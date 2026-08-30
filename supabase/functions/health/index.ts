import { corsHeaders, handleOptions } from "../_shared/cors.ts";
import { AppError, jsonError, jsonOk } from "../_shared/errors.ts";
import { correlationIdFrom, logInfo } from "../_shared/logging.ts";

Deno.serve(async (req) => {
  const correlationId = correlationIdFrom(req);
  const origin = req.headers.get("Origin");
  const headers = corsHeaders(origin);

  try {
    const preflight = handleOptions(req);
    if (preflight) return preflight;

    if (req.method !== "GET") {
      throw new AppError("method_not_allowed", "Use GET.", 405);
    }

    logInfo(correlationId, "health_check");
    return jsonOk(
      {
        status: "ok",
        service: "hope-tv-control-plane",
        product: "HOPE TV",
        time: new Date().toISOString(),
      },
      correlationId,
      200,
      headers,
    );
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});
