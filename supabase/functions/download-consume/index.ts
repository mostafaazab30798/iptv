/**
 * download-consume — kept for compatibility but now a no-op redirect.
 *
 * With GitHub Releases, the URL is returned directly by the `downloads`
 * function and the client fetches the release asset from GitHub's CDN.
 * There is no separate gateway hop, so this function is not needed in the
 * primary flow. It is retained in case a future download audit trail is added.
 */
import { corsHeaders, handleOptions } from "../_shared/cors.ts";
import { AppError, jsonError, jsonOk } from "../_shared/errors.ts";
import { correlationIdFrom } from "../_shared/logging.ts";

Deno.serve(async (req) => {
  const correlationId = correlationIdFrom(req);
  const headers = corsHeaders(req.headers.get("Origin"));

  try {
    const preflight = handleOptions(req);
    if (preflight) return preflight;

    // This endpoint is retired. The `downloads` function now returns a GitHub
    // Releases URL directly. Clients that call this endpoint should be
    // updated to use the URL from the `downloads` response instead.
    throw new AppError(
      "endpoint_retired",
      "This endpoint is no longer used. Fetch the downloadUrl from the /downloads response directly.",
      410,
    );
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});
