/**
 * Cloudflare Worker / Pages _worker.js for matches.hope-tv.site
 *
 * Provides a high-performance, cached, and CORS-enabled API for football matches.
 * Automatically synchronizes with the repo's daily scraped matches.json.
 */

const GITHUB_RAW_MATCHES =
  'https://raw.githubusercontent.com/mostafaazab30798/iptv/main/matches.json';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Accept, Range, User-Agent',
  'Access-Control-Max-Age': '86400',
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Handle preflight OPTIONS
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: CORS_HEADERS,
      });
    }

    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          ...CORS_HEADERS,
        },
      });
    }

    // Handle FotMob match details proxy with CORS
    if (url.pathname === '/fotmob/matchDetails') {
      const matchId = url.searchParams.get('matchId');
      if (!matchId) {
        return new Response(JSON.stringify({ error: 'matchId query param required' }), {
          status: 400,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            ...CORS_HEADERS,
          },
        });
      }
      const fotmobUrl = `https://www.fotmob.com/api/data/matchDetails?matchId=${matchId}`;

      try {
        const fotmobResp = await fetch(fotmobUrl, {
          headers: {
            'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Accept': 'application/json, text/plain, */*',
            'Referer': 'https://www.fotmob.com/',
          },
          cf: {
            cacheTtl: 30, // 30s cache for match details and events
            cacheEverything: true,
          },
        });

        if (fotmobResp.ok) {
          const body = await fotmobResp.text();
          return new Response(body, {
            status: 200,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Cache-Control': 'public, max-age=15, s-maxage=30',
              ...CORS_HEADERS,
            },
          });
        }
      } catch (err) {
        // Fallback below
      }

      return new Response(JSON.stringify({ error: 'FotMob upstream error' }), {
        status: 200,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cache-Control': 'no-cache',
          ...CORS_HEADERS,
        },
      });
    }

    // Handle FotMob real-time proxy with CORS
    if (url.pathname === '/fotmob/matches' || url.pathname === '/fotmob') {
      const now = new Date();
      const defaultDate = `${now.getUTCFullYear()}${String(now.getUTCMonth() + 1).padStart(2, '0')}${String(now.getUTCDate()).padStart(2, '0')}`;
      const date = url.searchParams.get('date') || defaultDate;
      const fotmobUrl = `https://www.fotmob.com/api/data/matches?date=${date}`;

      try {
        const fotmobResp = await fetch(fotmobUrl, {
          headers: {
            'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Accept': 'application/json, text/plain, */*',
            'Referer': 'https://www.fotmob.com/',
          },
          cf: {
            cacheTtl: 30, // 30s cache for live scores
            cacheEverything: true,
          },
        });

        if (fotmobResp.ok) {
          let body = await fotmobResp.text();
          const teamsQuery = url.searchParams.get('teams');
          if (teamsQuery) {
            try {
              const data = JSON.parse(body);
              const targets = teamsQuery
                .split(',')
                .map((t) => decodeURIComponent(t).trim().toLowerCase())
                .filter(Boolean);

              if (targets.length > 0 && Array.isArray(data.leagues)) {
                const filteredLeagues = [];
                for (const league of data.leagues) {
                  if (Array.isArray(league.matches)) {
                    const matchedMatches = league.matches.filter((m) => {
                      const hName = `${m.home?.name || ''} ${m.home?.longName || ''}`.toLowerCase();
                      const aName = `${m.away?.name || ''} ${m.away?.longName || ''}`.toLowerCase();
                      return targets.some(
                        (target) =>
                          hName.includes(target) ||
                          aName.includes(target) ||
                          target.includes(hName) ||
                          target.includes(aName),
                      );
                    });
                    if (matchedMatches.length > 0) {
                      filteredLeagues.push({
                        ...league,
                        matches: matchedMatches,
                      });
                    }
                  }
                }
                body = JSON.stringify({ leagues: filteredLeagues });
              }
            } catch (_) {
              // On parsing error, return unmodified body
            }
          }

          return new Response(body, {
            status: 200,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Cache-Control': 'public, max-age=15, s-maxage=30',
              ...CORS_HEADERS,
            },
          });
        }
      } catch (err) {
        // Fallback below
      }

      return new Response(JSON.stringify({ leagues: [], error: 'FotMob upstream error' }), {
        status: 200,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cache-Control': 'no-cache',
          ...CORS_HEADERS,
        },
      });
    }

    // Accept root /, /matches, or /matches.json
    const isMatchesRequest =
      url.pathname === '/' ||
      url.pathname === '/matches' ||
      url.pathname === '/matches.json';

    if (!isMatchesRequest) {
      // If assets binding is available (Cloudflare Pages static assets), try serving it
      if (env && env.ASSETS) {
        return env.ASSETS.fetch(request);
      }
    }

    try {
      // Fetch latest matches.json from GitHub with Cloudflare Edge caching
      const upstreamResponse = await fetch(GITHUB_RAW_MATCHES, {
        headers: {
          'User-Agent': 'HOPE-TV-Matches-API/1.0',
          'Accept': 'application/json',
        },
        cf: {
          cacheTtl: 300, // Cache for 5 minutes at Cloudflare edge
          cacheEverything: true,
        },
      });

      if (upstreamResponse.ok) {
        const matchesData = await upstreamResponse.text();
        return new Response(matchesData, {
          status: 200,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Cache-Control': 'public, max-age=60, s-maxage=300, stale-while-revalidate=600',
            ...CORS_HEADERS,
          },
        });
      }
    } catch (err) {
      // Network or upstream issue
    }

    // Fallback static empty array if upstream is unreachable
    return new Response(JSON.stringify([]), {
      status: 200,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cache-Control': 'no-cache',
        ...CORS_HEADERS,
      },
    });
  },
};
