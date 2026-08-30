import { verifyDownloadToken, type Env } from "./auth.ts";

export async function handleRequest(
  request: Request,
  env: Env,
  nowMs: number = Date.now(),
): Promise<Response> {
  const url = new URL(request.url);

  if (request.method === "GET" && url.pathname === "/health") {
    return Response.json({
      status: "ok",
      product: env.PRODUCT_NAME,
      service: "hope-tv-download-gateway",
      // Prove isolation: this worker does not load root IPTV worker.js
      iptvProxyCoupled: false,
    });
  }

  if (request.method !== "GET") {
    return Response.json(
      { error: { code: "method_not_allowed", message: "Use GET." } },
      { status: 405 },
    );
  }

  const match = url.pathname.match(/^\/v1\/downloads\/([^/]+)$/);
  if (!match) {
    return Response.json(
      { error: { code: "not_found", message: "Unknown route." } },
      { status: 404 },
    );
  }

  const token = decodeURIComponent(match[1]);
  const auth = await verifyDownloadToken(
    token,
    env,
    nowMs,
  );
  if (!auth.ok) {
    return Response.json(
      { error: { code: auth.code, message: auth.message } },
      { status: auth.status },
    );
  }

  const object = await env.RELEASES.get(auth.objectKey);
  if (!object) {
    return Response.json(
      { error: { code: "object_missing", message: "Release object not found." } },
      { status: 404 },
    );
  }

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set("etag", object.httpEtag);
  headers.set("cache-control", "private, no-store");
  headers.set("x-hope-release-id", auth.releaseId);

  return new Response(object.body, { headers });
}
