import { connect } from 'cloudflare:sockets';

/**
 * Cloudflare Worker: iptv
 *
 * 1. Hardened /proxy endpoint for CORS & Mixed-Content bypass on IPTV streams & APIs
 * 2. Serves Flutter Web static assets
 */

const ALLOWED_METHODS = new Set(['GET', 'HEAD', 'OPTIONS']);
const MAX_REDIRECTS = 5;

// High-speed in-isolate memory cache for IPTV panel API responses
const memoryCache = new Map();
const MEMORY_CACHE_MAX_ENTRIES = 150;

function getFromMemoryCache(key) {
  const entry = memoryCache.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    memoryCache.delete(key);
    return null;
  }
  return entry;
}

function setToMemoryCache(key, status, headersObj, bodyText, ttlSeconds) {
  if (memoryCache.size >= MEMORY_CACHE_MAX_ENTRIES) {
    const firstKey = memoryCache.keys().next().value;
    if (firstKey) memoryCache.delete(firstKey);
  }
  memoryCache.set(key, {
    status,
    headersObj,
    bodyText,
    expiresAt: Date.now() + (ttlSeconds * 1000),
  });
}

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

      // Check In-Memory & Edge Cache for idempotent panel API calls
      const cacheTtl = request.method === 'GET' ? getCacheTtl(targetParsed) : 0;
      if (cacheTtl > 0) {
        const memHit = getFromMemoryCache(targetUrl);
        if (memHit) {
          const respHeaders = new Headers(memHit.headersObj);
          applyCors(respHeaders, cors);
          respHeaders.set('X-Proxy-Cache', 'MEM-HIT');
          return new Response(memHit.bodyText, {
            status: memHit.status,
            headers: respHeaders,
          });
        }

        const cache = typeof caches !== 'undefined' && caches.default ? caches.default : null;
        if (cache) {
          try {
            const cacheKey = new Request(request.url, { method: 'GET' });
            const cachedResponse = await cache.match(cacheKey);
            if (cachedResponse) {
              const body = await cachedResponse.text();
              const cachedHeaders = new Headers(cachedResponse.headers);
              applyCors(cachedHeaders, cors);
              cachedHeaders.set('X-Proxy-Cache', 'EDGE-HIT');
              setToMemoryCache(targetUrl, cachedResponse.status, Object.fromEntries(cachedHeaders.entries()), body, cacheTtl);
              return new Response(body, {
                status: cachedResponse.status,
                headers: cachedHeaders,
              });
            }
          } catch (_) {}
        }
      }

      try {
        const upstreamResponse = await fetchWithRedirectGuard(targetParsed, request);

        const responseHeaders = new Headers(upstreamResponse.headers);
        applyCors(responseHeaders, cors);
        responseHeaders.set('Access-Control-Expose-Headers', 'Content-Length, Content-Range, Accept-Ranges, Content-Type');
        responseHeaders.set('Accept-Ranges', 'bytes');

        // Delete hop-by-hop & compression headers so the browser client doesn't receive mismatched lengths
        if (upstreamResponse.headers.has('content-encoding')) {
          responseHeaders.delete('content-encoding');
          responseHeaders.delete('content-length');
        }
        responseHeaders.delete('transfer-encoding');
        responseHeaders.delete('connection');
        responseHeaders.delete('keep-alive');

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

        // Cache successful JSON API responses in Memory and at Edge
        if (cacheTtl > 0 && upstreamResponse.status === 200) {
          try {
            const bodyText = await upstreamResponse.text();
            responseHeaders.set('X-Proxy-Cache', 'MISS');
            setToMemoryCache(targetUrl, 200, Object.fromEntries(responseHeaders.entries()), bodyText, cacheTtl);

            const cache = typeof caches !== 'undefined' && caches.default ? caches.default : null;
            if (cache) {
              const cacheHeaders = new Headers(responseHeaders);
              cacheHeaders.set('Cache-Control', `public, max-age=${cacheTtl}`);
              const toCache = new Response(bodyText, {
                status: 200,
                headers: cacheHeaders,
              });
              const cacheKey = new Request(request.url, { method: 'GET' });
              cache.put(cacheKey, toCache).catch(() => {});
            }

            return new Response(bodyText, {
              status: 200,
              headers: responseHeaders,
            });
          } catch (_) {}
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
            : (err && err.message ? err.message : 'Failed to fetch target URL via proxy');
        const status = err && err.code === 'BLOCKED_REDIRECT'
          ? 403
          : (err && err.name === 'AbortError' ? 504 : 502);
        return jsonError(status, message, cors);
      }
    }

    // -------------------------------------------------------------------------
    // 2. Static Assets (Flutter Web SPA)
    // -------------------------------------------------------------------------
    if (env.ASSETS) {
      const resp = await env.ASSETS.fetch(request);
      if (
        url.pathname === '/' ||
        url.pathname === '/index.html' ||
        url.pathname.endsWith('flutter_bootstrap.js') ||
        url.pathname.endsWith('flutter_service_worker.js')
      ) {
        const h = new Headers(resp.headers);
        h.set('Cache-Control', 'no-cache, no-store, must-revalidate');
        h.set('Pragma', 'no-cache');
        h.set('Expires', '0');
        return new Response(resp.body, {
          status: resp.status,
          statusText: resp.statusText,
          headers: h,
        });
      }
      return resp;
    }

    return fetch(request);
  },
};

function getCacheTtl(targetParsed) {
  if (!targetParsed.pathname.includes('player_api.php')) return 0;

  const action = targetParsed.searchParams.get('action');
  if (!action) {
    if (targetParsed.searchParams.has('username') && targetParsed.searchParams.has('password')) {
      return 300; // 5 minutes for auth / account info
    }
    return 0;
  }

  if (action === 'get_live_categories' || action === 'get_vod_categories' || action === 'get_series_categories') {
    return 3600; // 1 hour for categories
  }

  if (action === 'get_live_streams' || action === 'get_vod_streams' || action === 'get_series') {
    return 600; // 10 minutes for stream catalogs
  }

  if (action === 'get_short_epg') {
    return 300; // 5 minutes for EPG
  }

  return 0;
}

function corsHeaders(request) {
  const workerOrigin = new URL(request.url).origin;
  const requestOrigin = request.headers.get('Origin');
  const allowOrigin = requestOrigin || workerOrigin;
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

function isIpAddress(hostname) {
  const h = (hostname || '').toLowerCase().replace(/^\[|\]$/g, '');
  return /^(\d{1,3}\.){3}\d{1,3}$/.test(h) || h.includes(':');
}

const KNOWN_RESOLVED_IPS = {
  'fndueo.2m2h.im': ['31.59.212.51', '31.59.186.104'],
};

async function fetchFromIpSocket(targetUrl, request, originalHost = null) {
  const port = targetUrl.port
    ? parseInt(targetUrl.port, 10)
    : (targetUrl.protocol === 'https:' ? 443 : 80);
  const useTls = targetUrl.protocol === 'https:';

  const socket = connect(
    { hostname: targetUrl.hostname, port },
    { secureTransport: useTls ? 'on' : 'off' }
  );

  const writer = socket.writable.getWriter();
  const path = (targetUrl.pathname || '/') + (targetUrl.search || '');
  const hostHeader = originalHost || targetUrl.host;
  let reqLines = `${request.method} ${path} HTTP/1.1\r\n`;
  reqLines += `Host: ${hostHeader}\r\n`;
  reqLines += `User-Agent: IPTVSmartersPro/3.1.5.1 (iPad; iOS 16.5; Scale/2.00)\r\n`;
  reqLines += `Accept: */*\r\n`;
  reqLines += `Connection: close\r\n`;
  const range = request.headers.get('range');
  if (range) {
    reqLines += `Range: ${range}\r\n`;
  }
  reqLines += `\r\n`;

  await writer.write(new TextEncoder().encode(reqLines));
  writer.releaseLock();

  const reader = socket.readable.getReader();
  let buffer = new Uint8Array(0);
  let headerEndIndex = -1;

  while (headerEndIndex === -1) {
    const { done, value } = await reader.read();
    if (done) break;
    const newBuf = new Uint8Array(buffer.length + value.length);
    newBuf.set(buffer, 0);
    newBuf.set(value, buffer.length);
    buffer = newBuf;

    for (let i = 0; i <= buffer.length - 4; i++) {
      if (
        buffer[i] === 13 &&
        buffer[i + 1] === 10 &&
        buffer[i + 2] === 13 &&
        buffer[i + 3] === 10
      ) {
        headerEndIndex = i;
        break;
      }
    }
  }

  if (headerEndIndex === -1) {
    reader.releaseLock();
    try { socket.close(); } catch (_) {}
    throw new Error('Socket closed before response headers arrived');
  }

  const headerBytes = buffer.subarray(0, headerEndIndex);
  const remainingBody = buffer.subarray(headerEndIndex + 4);
  const headerStr = new TextDecoder().decode(headerBytes);
  const lines = headerStr.split('\r\n');
  const statusLine = lines[0] || 'HTTP/1.1 200 OK';
  const statusMatch = statusLine.match(/HTTP\/[\d.]+\s+(\d+)\s*(.*)/);
  const status = statusMatch ? parseInt(statusMatch[1], 10) : 200;
  const statusText = statusMatch ? statusMatch[2] : 'OK';

  const respHeaders = new Headers();
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i];
    const colon = line.indexOf(':');
    if (colon > 0) {
      const k = line.substring(0, colon).trim();
      const v = line.substring(colon + 1).trim();
      respHeaders.set(k, v);
    }
  }

  const bodyStream = new ReadableStream({
    start(controller) {
      if (remainingBody.length > 0) {
        controller.enqueue(remainingBody);
      }
    },
    async pull(controller) {
      try {
        const { done, value } = await reader.read();
        if (done) {
          controller.close();
          reader.releaseLock();
          try { socket.close(); } catch (_) {}
        } else {
          controller.enqueue(value);
        }
      } catch (err) {
        controller.error(err);
        reader.releaseLock();
        try { socket.close(); } catch (_) {}
      }
    },
    cancel() {
      reader.cancel().catch(() => {});
      try { socket.close(); } catch (_) {}
    },
  });

  return new Response(bodyStream, {
    status,
    statusText,
    headers: respHeaders,
  });
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

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 60000);

    let response;
    try {
      if (isIpAddress(current.hostname)) {
        response = await fetchFromIpSocket(current, request);
      } else {
        response = await fetch(current.toString(), {
          method: request.method,
          headers: upstreamHeaders,
          redirect: 'manual',
          signal: controller.signal,
        });

        // If Cloudflare edge returns 520-524 or 502-504, fallback to direct TCP socket
        if (response.status >= 500 && KNOWN_RESOLVED_IPS[current.hostname]) {
          const ips = KNOWN_RESOLVED_IPS[current.hostname];
          for (const ip of ips) {
            try {
              const ipUrl = new URL(current.toString());
              ipUrl.hostname = ip;
              const socketResp = await fetchFromIpSocket(ipUrl, request, current.host);
              if (socketResp && socketResp.status < 500) {
                response = socketResp;
                break;
              }
            } catch (_) {}
          }
        }
      }
    } catch (fetchErr) {
      if (KNOWN_RESOLVED_IPS[current.hostname]) {
        const ips = KNOWN_RESOLVED_IPS[current.hostname];
        for (const ip of ips) {
          try {
            const ipUrl = new URL(current.toString());
            ipUrl.hostname = ip;
            const socketResp = await fetchFromIpSocket(ipUrl, request, current.host);
            if (socketResp && socketResp.status < 500) {
              response = socketResp;
              break;
            }
          } catch (_) {}
        }
      }
      if (!response) {
        throw fetchErr;
      }
    } finally {
      clearTimeout(timeoutId);
    }

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

      // If redirect target is a raw IP address, check if initialUrl was a domain.
      // If so, rewrite hostname to initialUrl.hostname so Cloudflare Workers fetch()
      // can route through the cluster domain without triggering Error 1003.
      // If it remains an IP, fetchFromIpSocket will connect via direct TCP socket.
      const isIpV4 = /^(\d{1,3}\.){3}\d{1,3}$/.test(next.hostname);
      const isInitialDomain = !/^(\d{1,3}\.){3}\d{1,3}$/.test(initialUrl.hostname);
      if (isIpV4 && isInitialDomain) {
        next.hostname = initialUrl.hostname;
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
