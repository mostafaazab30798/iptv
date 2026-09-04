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
