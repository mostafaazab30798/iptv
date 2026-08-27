/**
 * Cloudflare Worker: iptv
 *
 * 1. Hardened /proxy endpoint for CORS & Mixed-Content bypass on IPTV streams & APIs
 * 2. Serves Flutter Web static assets
 */

const ALLOWED_METHODS = new Set(['GET', 'HEAD', 'OPTIONS']);
const MAX_REDIRECTS = 5;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // -------------------------------------------------------------------------
    // 1. IPTV Reverse Proxy Endpoint (/proxy?url=...)
    // -------------------------------------------------------------------------
    if (url.pathname === '/proxy' || url.pathname.startsWith('/proxy')) {
      const cors = corsHeaders(request);

      if (request.method === 'OPTIONS') {
        return new Response(null, {
          status: 204,
          headers: {
            ...cors,
            'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
            'Access-Control-Allow-Headers': request.headers.get('Access-Control-Request-Headers') || 'Range, Content-Type, Accept',
            'Access-Control-Max-Age': '86400',
          },
        });
      }

      if (!ALLOWED_METHODS.has(request.method)) {
        return jsonError(405, 'Method not allowed', cors);
      }

      const targetUrl = url.searchParams.get('url');
      if (!targetUrl) {
        return jsonError(400, 'Missing required "url" query parameter', cors);
      }

      let targetParsed;
      try {
        targetParsed = new URL(targetUrl);
      } catch (_) {
        return jsonError(400, 'Invalid target URL', cors);
      }

      if (targetParsed.protocol !== 'http:' && targetParsed.protocol !== 'https:') {
        return jsonError(400, 'Only http and https URLs are allowed', cors);
      }

      if (isBlockedHostname(targetParsed.hostname)) {
        return jsonError(403, 'Target host is not allowed', cors);
      }

      try {
        const upstreamResponse = await fetchWithRedirectGuard(targetParsed, request);

        const responseHeaders = new Headers(upstreamResponse.headers);
        applyCors(responseHeaders, cors);
        responseHeaders.set('Access-Control-Expose-Headers', 'Content-Length, Content-Range, Accept-Ranges, Content-Type');

        // Rewrite M3U8 playlists so child segments and sub-manifests route through the proxy
        const contentType = (upstreamResponse.headers.get('content-type') || '').toLowerCase();
        const isM3u8 =
          targetParsed.pathname.includes('.m3u8') ||
          contentType.includes('mpegurl') ||
          contentType.includes('application/x-mpegurl');

        if (isM3u8 && upstreamResponse.ok) {
          const text = await upstreamResponse.text();
          const lines = text.split('\n');
          const rewrittenLines = lines.map((line) => {
            const trimmed = line.trim();
            if (!trimmed || trimmed.startsWith('#')) return line;
            try {
              const absoluteUrl = new URL(trimmed, targetParsed).toString();
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
        const message =
          err && err.code === 'BLOCKED_REDIRECT'
            ? 'Redirect target is not allowed'
            : 'Failed to fetch target URL via proxy';
        return jsonError(err && err.code === 'BLOCKED_REDIRECT' ? 403 : 502, message, cors);
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

function corsHeaders(request) {
  const workerOrigin = new URL(request.url).origin;
  const requestOrigin = request.headers.get('Origin');
  const allowOrigin =
    requestOrigin && requestOrigin === workerOrigin ? requestOrigin : workerOrigin;
  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Vary': 'Origin',
  };
}

function applyCors(headers, cors) {
  for (const [key, value] of Object.entries(cors)) {
    headers.set(key, value);
  }
  headers.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
}

function jsonError(status, message, cors) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...cors,
      'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
    },
  });
}

function isBlockedHostname(hostname) {
  const h = (hostname || '').toLowerCase().replace(/^\[|\]$/g, '');

  if (
    h === 'localhost' ||
    h === 'metadata.google.internal' ||
    h === 'metadata' ||
    h.endsWith('.localhost') ||
    h.endsWith('.local') ||
    h.endsWith('.internal')
  ) {
    return true;
  }

  // IPv6 localhost / ULA / link-local
  if (h === '::1' || h === '0:0:0:0:0:0:0:1') return true;
  if (h.startsWith('fe80:') || h.startsWith('fc') || h.startsWith('fd')) return true;

  // IPv4 dotted-decimal
  const ipv4 = h.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
  if (ipv4) {
    const parts = ipv4.slice(1).map((p) => Number(p));
    if (parts.some((p) => p > 255)) return true;
    const [a, b] = parts;
    if (a === 0) return true; // 0.0.0.0/8
    if (a === 10) return true; // 10.0.0.0/8
    if (a === 127) return true; // 127.0.0.0/8
    if (a === 169 && b === 254) return true; // link-local / cloud metadata
    if (a === 172 && b >= 16 && b <= 31) return true; // 172.16.0.0/12
    if (a === 192 && b === 168) return true; // 192.168.0.0/16
    if (a === 100 && b >= 64 && b <= 127) return true; // CGNAT 100.64.0.0/10
  }

  return false;
}

async function fetchWithRedirectGuard(initialUrl, request) {
  let current = initialUrl;

  for (let i = 0; i <= MAX_REDIRECTS; i++) {
    if (isBlockedHostname(current.hostname)) {
      const err = new Error('Blocked host');
      err.code = 'BLOCKED_REDIRECT';
      throw err;
    }

    const upstreamHeaders = new Headers();
    upstreamHeaders.set('Host', current.host);
    upstreamHeaders.set(
      'User-Agent',
      'IPTVSmartersPro/3.1.5.1 (iPad; iOS 16.5; Scale/2.00)'
    );
    upstreamHeaders.set('Accept', '*/*');

    const range = request.headers.get('range');
    if (range) {
      upstreamHeaders.set('Range', range);
    }

    const response = await fetch(current.toString(), {
      method: request.method,
      headers: upstreamHeaders,
      redirect: 'manual',
    });

    if (response.status >= 300 && response.status < 400) {
      const location = response.headers.get('Location');
      if (!location) {
        return response;
      }
      let next;
      try {
        next = new URL(location, current);
      } catch (_) {
        const err = new Error('Invalid redirect');
        err.code = 'BLOCKED_REDIRECT';
        throw err;
      }
      if (next.protocol !== 'http:' && next.protocol !== 'https:') {
        const err = new Error('Invalid redirect protocol');
        err.code = 'BLOCKED_REDIRECT';
        throw err;
      }
      current = next;
      continue;
    }

    return response;
  }

  const err = new Error('Too many redirects');
  err.code = 'BLOCKED_REDIRECT';
  throw err;
}
