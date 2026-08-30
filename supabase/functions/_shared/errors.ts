/**
 * Structured error responses. Never leak secrets or IPTV credentials.
 */

export class AppError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly status = 400,
    public readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "AppError";
  }
}

export function jsonError(
  error: unknown,
  correlationId: string,
  extraHeaders: HeadersInit = {},
): Response {
  if (error instanceof AppError) {
    return new Response(
      JSON.stringify({
        error: {
          code: error.code,
          message: error.message,
          details: error.details ?? null,
          correlationId,
        },
      }),
      {
        status: error.status,
        headers: {
          "Content-Type": "application/json",
          "X-Correlation-Id": correlationId,
          ...extraHeaders,
        },
      },
    );
  }

  return new Response(
    JSON.stringify({
      error: {
        code: "internal_error",
        message: "An unexpected error occurred.",
        correlationId,
      },
    }),
    {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "X-Correlation-Id": correlationId,
        ...extraHeaders,
      },
    },
  );
}

export function jsonOk(
  body: unknown,
  correlationId: string,
  status = 200,
  extraHeaders: HeadersInit = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "X-Correlation-Id": correlationId,
      ...extraHeaders,
    },
  });
}
