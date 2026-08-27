/**
 * Cloudflare Worker / Pages _worker.js
 *
 * Hardened /proxy endpoint + Flutter Web static assets.
 * Mirrors worker.js proxy policy (GET/HEAD, public http(s) only, same-origin CORS).
 */

const ALLOWED_METHODS = new Set(['GET', 'HEAD', 'OPTIONS']);
const MAX_REDIRECTS = 5;

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // -------------------------------------------------------------------------
    // 1. IPTV Reverse Proxy Endpoint (/proxy?url=...)
    // -------------------------------------------------------------------------
    if (url.pathname === '/proxy' || url.pathname.startsWith('/proxy/')) {
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
        return jsonError(400, 'Missing required query parameter "url"', cors);
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

  if (h === '::1' || h === '0:0:0:0:0:0:0:1') return true;
  if (h.startsWith('fe80:') || h.startsWith('fc') || h.startsWith('fd')) return true;

  const ipv4 = h.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
  if (ipv4) {
    const parts = ipv4.slice(1).map((p) => Number(p));
    if (parts.some((p) => p > 255)) return true;
    const [a, b] = parts;
    if (a === 0) return true;
    if (a === 10) return true;
    if (a === 127) return true;
    if (a === 169 && b === 254) return true;
    if (a === 172 && b >= 16 && b <= 31) return true;
    if (a === 192 && b === 168) return true;
    if (a === 100 && b >= 64 && b <= 127) return true;
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
