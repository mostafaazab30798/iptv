/**
 * Cloudflare Worker: iptv
 * 
 * 1. Handles /proxy endpoint for CORS & HTTP Mixed-Content bypass on IPTV streams & APIs
 * 2. Serves Flutter Web static assets
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // -------------------------------------------------------------------------
    // 1. IPTV Reverse Proxy Endpoint (/proxy?url=...)
    // -------------------------------------------------------------------------
    if (url.pathname === '/proxy' || url.pathname.startsWith('/proxy')) {
      // Handle CORS preflight OPTIONS
      if (request.method === 'OPTIONS') {
        return new Response(null, {
          status: 204,
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, HEAD, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': '*',
            'Access-Control-Max-Age': '86400',
          },
        });
      }

      const targetUrl = url.searchParams.get('url');
      if (!targetUrl) {
        return new Response(
          JSON.stringify({ error: 'Missing required "url" query parameter' }),
          {
            status: 400,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
            },
          }
        );
      }

      try {
        const targetParsed = new URL(targetUrl);
        const upstreamHeaders = new Headers();
        upstreamHeaders.set('Host', targetParsed.host);
        upstreamHeaders.set(
          'User-Agent',
          'IPTVSmartersPro/3.1.5.1 (iPad; iOS 16.5; Scale/2.00)'
        );
        upstreamHeaders.set('Accept', '*/*');

        // Forward Range header for video seeking / streaming
        const range = request.headers.get('range');
        if (range) {
          upstreamHeaders.set('Range', range);
        }

        const upstreamResponse = await fetch(targetParsed.toString(), {
          method: request.method,
          headers: upstreamHeaders,
          redirect: 'follow',
        });

        const responseHeaders = new Headers(upstreamResponse.headers);
        responseHeaders.set('Access-Control-Allow-Origin', '*');
        responseHeaders.set('Access-Control-Allow-Methods', 'GET, HEAD, POST, OPTIONS');
        responseHeaders.set('Access-Control-Allow-Headers', '*');
        responseHeaders.set('Access-Control-Expose-Headers', '*');

        // Rewrite M3U8 playlists so child segments and sub-manifests route through the proxy
        const contentType = (upstreamResponse.headers.get('content-type') || '').toLowerCase();
        const isM3u8 = targetUrl.includes('.m3u8') || contentType.includes('mpegurl') || contentType.includes('application/x-mpegurl');

        if (isM3u8 && upstreamResponse.ok) {
          const text = await upstreamResponse.text();
          const targetBase = new URL(targetUrl);
          const lines = text.split('\n');
          const rewrittenLines = lines.map((line) => {
            const trimmed = line.trim();
            if (!trimmed || trimmed.startsWith('#')) return line;
            try {
              const absoluteUrl = new URL(trimmed, targetBase).toString();
              return `${url.origin}/proxy?url=${encodeURIComponent(absoluteUrl)}`;
            } catch (_) {
              return line;
            }
          });

          return new Response(rewrittenLines.join('\n'), {
            status: upstreamResponse.status,
            headers: responseHeaders,
          });
        }

        return new Response(upstreamResponse.body, {
          status: upstreamResponse.status,
          statusText: upstreamResponse.statusText,
          headers: responseHeaders,
        });
      } catch (err) {
        return new Response(
          JSON.stringify({
            error: 'Failed to fetch target URL via Cloudflare Worker proxy',
            details: err.message,
          }),
          {
            status: 502,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
            },
          }
        );
      }
    }

    // -------------------------------------------------------------------------
    // 2. Static Assets (Flutter Web SPA)
    // -------------------------------------------------------------------------
    if (env.ASSETS) {
      return env.ASSETS.fetch(request);
    }

    return fetch(request);
  },
};
