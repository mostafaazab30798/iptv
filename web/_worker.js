/**
 * Cloudflare Worker / Pages _worker.js
 * 
 * Handles:
 * 1. /proxy endpoint to bypass Mixed Content (HTTP on HTTPS) and CORS restrictions for IPTV APIs & streams
 * 2. Serving static Flutter Web assets
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // -------------------------------------------------------------------------
    // 1. IPTV Reverse Proxy Endpoint (/proxy?url=...)
    // -------------------------------------------------------------------------
    if (url.pathname === '/proxy' || url.pathname.startsWith('/proxy/')) {
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
          JSON.stringify({ error: 'Missing required query parameter "url"' }),
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
        const upstreamHeaders = new Headers();
        upstreamHeaders.set(
          'User-Agent',
          'IPTVSmartersPro/3.1.5.1 (iPad; iOS 16.5; Scale/2.00)'
        );
        upstreamHeaders.set('Accept', '*/*');

        // Forward Range header for video seeking / partial content
        const range = request.headers.get('range');
        if (range) {
          upstreamHeaders.set('Range', range);
        }

        const upstreamResponse = await fetch(targetUrl, {
          method: request.method,
          headers: upstreamHeaders,
          redirect: 'follow',
        });

        // Clone headers and append CORS headers
        const responseHeaders = new Headers(upstreamResponse.headers);
        responseHeaders.set('Access-Control-Allow-Origin', '*');
        responseHeaders.set('Access-Control-Allow-Methods', 'GET, HEAD, POST, OPTIONS');
        responseHeaders.set('Access-Control-Allow-Headers', '*');
        responseHeaders.set('Access-Control-Expose-Headers', '*');

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
