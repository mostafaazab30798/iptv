#!/usr/bin/env bash
# Example encrypted logical backup for HOPE TV control-plane PostgreSQL.
# Run from a secure operator workstation — never commit credentials.
set -euo pipefail

if [[ -z "${SUPABASE_DB_URL:-}" ]]; then
  echo "Set SUPABASE_DB_URL to the target database connection string." >&2
  exit 1
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="hope-tv-${STAMP}.dump"

pg_dump "$SUPABASE_DB_URL" --format=custom --file="$OUT"
echo "Wrote $OUT"
echo "Encrypt with: gpg --symmetric --cipher-algo AES256 $OUT"
