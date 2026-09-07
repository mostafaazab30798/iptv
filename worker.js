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

// Short-lived panel→CDN redirect cache so Range seeks skip the panel round-trip.
const redirectCache = new Map();
const REDIRECT_CACHE_MAX = 200;
const REDIRECT_CACHE_TTL_MS = 5 * 60 * 1000;

function getCachedRedirect(urlKey) {
  const entry = redirectCache.get(urlKey);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    redirectCache.delete(urlKey);
    return null;
  }
  return entry.target;
}

function setCachedRedirect(urlKey, targetHref) {
  if (redirectCache.size >= REDIRECT_CACHE_MAX) {
    const firstKey = redirectCache.keys().next().value;
    if (firstKey) redirectCache.delete(firstKey);
  }
  redirectCache.set(urlKey, {
    target: targetHref,
    expiresAt: Date.now() + REDIRECT_CACHE_TTL_MS,
  });
}

function deleteCachedRedirect(urlKey) {
  redirectCache.delete(urlKey);
}

function isHlsPlaylistRequest(targetParsed, proxyPathname) {
  const path = (targetParsed.pathname || '').toLowerCase();
  return (
    path.includes('.m3u8') ||
    (proxyPathname || '').endsWith('.m3u8')
  );
}

function isProgressiveMediaPath(pathname) {
  const p = (pathname || '').toLowerCase();
  if (p.includes('.m3u8')) return false;
  if (/\.(mkv|mp4|avi|mov|m4v|m4a|mp3|flac|aac|ts)(\?|$)/i.test(p)) return true;
  if (p.includes('/movie/') || p.includes('/series/')) return true;
  if (p.includes('/live/') && p.endsWith('.ts')) return true;
  return false;
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
        const hlsMode = isHlsPlaylistRequest(targetParsed, url.pathname);
        const { response: upstreamResponse, finalUrl, clientRedirectLocation } =
          await fetchWithRedirectGuard(targetParsed, request, {
            proxyOrigin: url.origin,
            // VOD/live.ts: hand CDN URL back to the player so Range seeks
            // hit the CDN through /proxy instead of re-resolving the panel.
            passRedirectToClient:
              !hlsMode && isProgressiveMediaPath(targetParsed.pathname),
          });

        if (clientRedirectLocation) {
          const redirectHeaders = new Headers({
            Location: clientRedirectLocation,
            'Cache-Control': 'no-store',
          });
          applyCors(redirectHeaders, cors);
          redirectHeaders.set('Access-Control-Expose-Headers', 'Location, Content-Length, Content-Range, Accept-Ranges, Content-Type');
          return new Response(null, {
            status: 302,
            headers: redirectHeaders,
          });
        }

        const responseHeaders = new Headers(upstreamResponse.headers);
        applyCors(responseHeaders, cors);
        responseHeaders.set('Access-Control-Expose-Headers', 'Content-Length, Content-Range, Accept-Ranges, Content-Type, Location');
        // Never advertise byte seeking when the upstream does not support it.
        // Safari trusts this header and can otherwise enter a permanent wait
        // after issuing a range request that receives a full 200 response.
        const upstreamAcceptRanges = upstreamResponse.headers.get('accept-ranges');
        if (upstreamResponse.status === 206 || upstreamAcceptRanges) {
          responseHeaders.set(
            'Accept-Ranges',
            upstreamAcceptRanges || 'bytes'
          );
        } else {
          responseHeaders.delete('Accept-Ranges');
        }

        // Prefer explicit Content-Length for media_kit seeking when upstream had one.
        const upstreamLength = upstreamResponse.headers.get('content-length');
        if (upstreamLength) {
          responseHeaders.set('Content-Length', upstreamLength);
        }
        const upstreamRange = upstreamResponse.headers.get('content-range');
        if (upstreamRange) {
          responseHeaders.set('Content-Range', upstreamRange);
        }

        // Delete hop-by-hop & compression headers so the browser client doesn't receive mismatched lengths
        if (upstreamResponse.headers.has('content-encoding')) {
          responseHeaders.delete('content-encoding');
          responseHeaders.delete('content-length');
        }
        responseHeaders.delete('transfer-encoding');
        responseHeaders.delete('connection');
        responseHeaders.delete('keep-alive');

        // Rewrite M3U8 playlists so child segments and sub-manifests route through the proxy.
        // Use the final URL (after CDN redirects) as the base for relative /hls/... paths.
        const contentType = (upstreamResponse.headers.get('content-type') || '').toLowerCase();
        const pathLooksLikeM3u8 =
          targetParsed.pathname.includes('.m3u8') ||
          url.pathname.endsWith('.m3u8') ||
          finalUrl.pathname.includes('.m3u8');
        const typeLooksLikeM3u8 =
          contentType.includes('mpegurl') ||
          contentType.includes('application/x-mpegurl') ||
          contentType.includes('application/vnd.apple.mpegurl');

        if ((pathLooksLikeM3u8 || typeLooksLikeM3u8) && upstreamResponse.ok) {
          const text = await upstreamResponse.text();
          if (text.includes('#EXTM3U')) {
            responseHeaders.set('Content-Type', 'application/vnd.apple.mpegurl');
            responseHeaders.set('Cache-Control', 'no-cache, no-store, must-revalidate');
            responseHeaders.delete('content-length');

            const rewritten = rewriteM3u8Playlist(text, finalUrl, url.origin);
            return new Response(rewritten, {
              status: upstreamResponse.status,
              headers: responseHeaders,
            });
          }
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
        url.pathname.endsWith('flutter_service_worker.js') ||
        url.pathname.endsWith('/js/hope_tv_native_vod.js')
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

const IPTV_UA = 'IPTVSmartersPro/3.1.5.1 (iPad; iOS 16.5; Scale/2.00)';

// Panels that block Cloudflare edge IPs; fall back to direct TCP sockets.
const KNOWN_RESOLVED_IPS = {
  'fndueo.2m2h.im': ['31.59.212.51', '31.59.186.104'],
};

function shouldTrySocketFallback(status) {
  return (
    status === 401 ||
    status === 403 ||
    status === 407 ||
    status === 429 ||
    status === 520 ||
    status === 521 ||
    status === 522 ||
    status === 523 ||
    status === 524 ||
    status >= 500
  );
}

function buildUpstreamHeaders(request, targetUrl) {
  const upstreamHeaders = new Headers();
  upstreamHeaders.set('User-Agent', IPTV_UA);
  upstreamHeaders.set('Accept', '*/*');
  // Many IPTV panels/CDNs require a panel-origin Referer.
  try {
    upstreamHeaders.set('Referer', `${targetUrl.protocol}//${targetUrl.host}/`);
    upstreamHeaders.set('Origin', `${targetUrl.protocol}//${targetUrl.host}`);
  } catch (_) {}

  const range = request.headers.get('range');
  if (range) {
    upstreamHeaders.set('Range', range);
    // Avoid compressed byte offsets, which make Content-Range unusable for
    // native media seeking.
    upstreamHeaders.set('Accept-Encoding', 'identity');
  }
  const ifRange = request.headers.get('if-range');
  if (ifRange) {
    upstreamHeaders.set('If-Range', ifRange);
  }
  return upstreamHeaders;
}

function rewriteM3u8Playlist(text, baseUrl, proxyOrigin) {
  const lines = text.split('\n');
  return lines
    .map((line) => {
      const trimmed = line.trim();
      if (!trimmed) return line;

      if (trimmed.startsWith('#EXT-X-KEY') || trimmed.startsWith('#EXT-X-MAP')) {
        return line.replace(/URI="([^"]+)"/i, (match, uri) => {
          try {
            const resolved = new URL(uri, baseUrl).href;
            return `URI="${proxyOrigin}/proxy?url=${encodeURIComponent(resolved)}"`;
          } catch (_) {
            return match;
          }
        });
      }

      if (trimmed.startsWith('#')) return line;

      try {
        const absoluteUrl = new URL(trimmed, baseUrl).toString();
        return `${proxyOrigin}/proxy?url=${encodeURIComponent(absoluteUrl)}`;
      } catch (_) {
        return line;
      }
    })
    .join('\n');
}

async function resolveHostnameIps(hostname) {
  const known = KNOWN_RESOLVED_IPS[hostname.toLowerCase()];
  if (known && known.length) return known.slice();

  try {
    const dohUrl =
      `https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(hostname)}&type=A`;
    const resp = await fetch(dohUrl, {
      headers: { Accept: 'application/dns-json' },
    });
    if (!resp.ok) return [];
    const data = await resp.json();
    const answers = Array.isArray(data.Answer) ? data.Answer : [];
    return answers
      .filter((a) => a && a.type === 1 && typeof a.data === 'string')
      .map((a) => a.data)
      .filter((ip) => !isBlockedHostname(ip));
  } catch (_) {
    return [];
  }
}

async function fetchViaResolvedIps(targetUrl, request, hostHeader) {
  const ips = await resolveHostnameIps(targetUrl.hostname);
  let lastResponse = null;
  for (const ip of ips) {
    try {
      const ipUrl = new URL(targetUrl.toString());
      ipUrl.hostname = ip;
      const socketResp = await fetchFromIpSocket(ipUrl, request, hostHeader || targetUrl.host);
      lastResponse = socketResp;
      if (socketResp && !shouldTrySocketFallback(socketResp.status)) {
        return socketResp;
      }
      // Keep trying other IPs on auth/edge blocks; 3xx is usable (redirect loop handles it).
      if (socketResp && socketResp.status >= 300 && socketResp.status < 400) {
        return socketResp;
      }
      if (socketResp && socketResp.ok) {
        return socketResp;
      }
    } catch (_) {}
  }
  return lastResponse;
}

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
  const refererOrigin = originalHost
    ? `${targetUrl.protocol}//${originalHost}/`
    : `${targetUrl.protocol}//${targetUrl.host}/`;

  let reqLines = `${request.method} ${path} HTTP/1.1\r\n`;
  reqLines += `Host: ${hostHeader}\r\n`;
  reqLines += `User-Agent: ${IPTV_UA}\r\n`;
  reqLines += `Accept: */*\r\n`;
  reqLines += `Referer: ${refererOrigin}\r\n`;
  reqLines += `Connection: close\r\n`;
  const range = request.headers.get('range');
  if (range) {
    reqLines += `Range: ${range}\r\n`;
    reqLines += `Accept-Encoding: identity\r\n`;
  }
  const ifRange = request.headers.get('if-range');
  if (ifRange) {
    reqLines += `If-Range: ${ifRange}\r\n`;
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

/**
 * Fetch target following redirects manually.
 * Returns { response, finalUrl, clientRedirectLocation? }.
 *
 * Important: do NOT rewrite CDN redirect IPs back to the panel hostname — segments
 * like /hls/... only work on the CDN that issued the tokenized playlist.
 */
async function fetchWithRedirectGuard(initialUrl, request, options = {}) {
  const proxyOrigin = options.proxyOrigin || null;
  const passRedirectToClient = !!options.passRedirectToClient;

  let current = initialUrl;
  let panelHostHeader = isIpAddress(initialUrl.hostname) ? null : initialUrl.host;
  const cacheKey = initialUrl.href;

  // Reuse a recent panel→CDN redirect so Range seeks skip the panel.
  const cachedTarget = getCachedRedirect(cacheKey);
  if (cachedTarget) {
    try {
      current = new URL(cachedTarget);
    } catch (_) {}
  }

  for (let i = 0; i <= MAX_REDIRECTS; i++) {
    if (isBlockedHostname(current.hostname)) {
      const err = new Error('Blocked host');
      err.code = 'BLOCKED_REDIRECT';
      throw err;
    }

    const upstreamHeaders = buildUpstreamHeaders(request, current);
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 60000);

    let response;
    const preferSocket =
      isIpAddress(current.hostname) ||
      !!KNOWN_RESOLVED_IPS[(current.hostname || '').toLowerCase()];

    try {
      if (preferSocket && !isIpAddress(current.hostname)) {
        // Known IPTV panels block Cloudflare egress — go straight to TCP.
        const socketResp = await fetchViaResolvedIps(
          current,
          request,
          current.host
        );
        if (socketResp) {
          response = socketResp;
        }
      }

      if (!response) {
        if (isIpAddress(current.hostname)) {
          response = await fetchFromIpSocket(current, request, current.host);
        } else {
          response = await fetch(current.toString(), {
            method: request.method,
            headers: upstreamHeaders,
            redirect: 'manual',
            signal: controller.signal,
          });

          if (shouldTrySocketFallback(response.status)) {
            const socketResp = await fetchViaResolvedIps(
              current,
              request,
              current.host
            );
            if (socketResp) {
              response = socketResp;
            }
          }
        }
      }
    } catch (fetchErr) {
      const socketResp = await fetchViaResolvedIps(
        current,
        request,
        panelHostHeader || current.host
      );
      if (socketResp) {
        response = socketResp;
      } else if (cachedTarget && current.href === cachedTarget) {
        // CDN tokens can expire before the cache entry. Retry through the
        // panel so it can issue a fresh redirect instead of failing every
        // subsequent Range seek against the stale CDN URL.
        deleteCachedRedirect(cacheKey);
        current = initialUrl;
        panelHostHeader = isIpAddress(initialUrl.hostname)
          ? null
          : initialUrl.host;
        continue;
      } else {
        throw fetchErr;
      }
    } finally {
      clearTimeout(timeoutId);
    }

    if (response.status >= 300 && response.status < 400) {
      const location = response.headers.get('Location');
      if (!location) {
        return { response, finalUrl: current };
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
      if (isBlockedHostname(next.hostname)) {
        const err = new Error('Blocked host');
        err.code = 'BLOCKED_REDIRECT';
        throw err;
      }

      // Cache panel→CDN mapping for subsequent Range requests.
      setCachedRedirect(cacheKey, next.href);

      // Progressive VOD/live.ts: let the player follow a same-origin proxy
      // redirect so later seeks target the CDN URL directly.
      if (passRedirectToClient && proxyOrigin && i === 0 && !cachedTarget) {
        return {
          response,
          finalUrl: next,
          clientRedirectLocation: `${proxyOrigin}/proxy?url=${encodeURIComponent(next.href)}`,
        };
      }

      current = next;
      continue;
    }

    if (
      cachedTarget &&
      current.href === cachedTarget &&
      shouldTrySocketFallback(response.status)
    ) {
      deleteCachedRedirect(cacheKey);
      current = initialUrl;
      panelHostHeader = isIpAddress(initialUrl.hostname)
        ? null
        : initialUrl.host;
      continue;
    }

    return { response, finalUrl: current };
  }

  const err = new Error('Too many redirects');
  err.code = 'BLOCKED_REDIRECT';
  throw err;
}
