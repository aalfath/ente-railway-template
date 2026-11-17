#!/bin/sh
# Start museum on Railway: turn the generated hex secrets into the base64 keys
# museum expects, fill in fixed settings, then exec the upstream binary.
# museum reads any config key from ENTE_<KEY> (dots and dashes become "_").
set -eu

fail() { echo "ente-railway: $*" >&2; exit 1; }

# hex string -> base64 (StdEncoding)
hex2b64() { printf '%s' "$1" | xxd -r -p | base64 | tr -d '\n'; }

need_hex() { # name value expected-length
  case "$2" in *[!0-9a-fA-F]*|'') fail "$1 must be $3 hex characters";; esac
  [ "${#2}" -eq "$3" ] || fail "$1 must be $3 hex characters (got ${#2})"
}

# Keys: an explicit base64 ENTE_KEY_* / ENTE_JWT_SECRET (for example when moving
# an existing instance here) wins; otherwise derive them from the hex secrets.
# Never fall back to the fixed sample keys in upstream's local.yaml.
if [ -z "${ENTE_KEY_ENCRYPTION:-}" ]; then
  need_hex MUSEUM_ENCRYPTION_KEY_HEX "${MUSEUM_ENCRYPTION_KEY_HEX:-}" 64
  ENTE_KEY_ENCRYPTION=$(hex2b64 "$MUSEUM_ENCRYPTION_KEY_HEX")
fi
if [ -z "${ENTE_KEY_HASH:-}" ]; then
  need_hex MUSEUM_HASH_KEY_HEX "${MUSEUM_HASH_KEY_HEX:-}" 128
  ENTE_KEY_HASH=$(hex2b64 "$MUSEUM_HASH_KEY_HEX")
fi
if [ -z "${ENTE_JWT_SECRET:-}" ]; then
  need_hex MUSEUM_JWT_SECRET_HEX "${MUSEUM_JWT_SECRET_HEX:-}" 64
  ENTE_JWT_SECRET=$(hex2b64 "$MUSEUM_JWT_SECRET_HEX" | tr '+/' '-_')
fi
export ENTE_KEY_ENCRYPTION ENTE_KEY_HASH ENTE_JWT_SECRET

# HTTP port: Railway's PORT.
export ENTE_HTTP_PORT="${ENTE_HTTP_PORT:-${PORT:-8080}}"

# Database (Railway Postgres over the private network).
[ -n "${ENTE_DB_HOST:-}" ] || fail "ENTE_DB_HOST is empty (reference the Postgres service)"
export ENTE_DB_SSLMODE="${ENTE_DB_SSLMODE:-require}"

# Object storage: the primary bucket "b2-eu-cen" (the name is fixed by Ente,
# it has nothing to do with Backblaze). Railway Buckets use TLS and
# virtual-hosted URLs.
[ -n "${ENTE_S3_B2_EU_CEN_BUCKET:-}" ] || fail "ENTE_S3_B2_EU_CEN_BUCKET is empty (reference the bucket)"
export ENTE_S3_ARE_LOCAL_BUCKETS="${ENTE_S3_ARE_LOCAL_BUCKETS:-false}"
export ENTE_S3_USE_PATH_STYLE_URLS="${ENTE_S3_USE_PATH_STYLE_URLS:-false}"

# Browser uploads go straight from the Photos web app to the bucket through
# presigned URLs, so the bucket needs a CORS rule or every web upload fails.
# Railway Buckets start with none: set Ente's recommended rule on each start
# (idempotent). Set ENTE_RAILWAY_BUCKET_CORS=false to manage CORS yourself.
set_bucket_cors() {
  ep="${ENTE_S3_B2_EU_CEN_ENDPOINT:-}"; [ -n "$ep" ] || return 1
  case "$ep" in http://*|https://*) ;; *) ep="https://$ep";; esac
  scheme="${ep%%://*}"; host="${ep#*://}"; host="${host%%/*}"
  if [ "$ENTE_S3_USE_PATH_STYLE_URLS" = "true" ]; then
    url="$scheme://$host/$ENTE_S3_B2_EU_CEN_BUCKET/?cors"
  else
    url="$scheme://$ENTE_S3_B2_EU_CEN_BUCKET.$host/?cors"
  fi
  xml='<CORSConfiguration><CORSRule><AllowedOrigin>*</AllowedOrigin><AllowedMethod>GET</AllowedMethod><AllowedMethod>HEAD</AllowedMethod><AllowedMethod>PUT</AllowedMethod><AllowedMethod>POST</AllowedMethod><AllowedMethod>DELETE</AllowedMethod><AllowedHeader>*</AllowedHeader><ExposeHeader>ETag</ExposeHeader><MaxAgeSeconds>3000</MaxAgeSeconds></CORSRule></CORSConfiguration>'
  md5=$(printf '%s' "$xml" | md5sum | cut -d' ' -f1 | xxd -r -p | base64)
  # credentials go through a curl config on stdin, not the process list
  code=$(printf 'user = "%s:%s"\n' "${ENTE_S3_B2_EU_CEN_KEY:-}" "${ENTE_S3_B2_EU_CEN_SECRET:-}" |
    curl -sS -o /tmp/cors.out -w '%{http_code}' -K - --max-time 20 \
      --aws-sigv4 "aws:amz:${ENTE_S3_B2_EU_CEN_REGION:-auto}:s3" \
      -X PUT -H "Content-MD5: $md5" -H 'Content-Type: application/xml' \
      --data-binary "$xml" "$url") || code=000
  [ "$code" = 200 ]
}
if [ "${ENTE_RAILWAY_BUCKET_CORS:-true}" != "false" ]; then
  if set_bucket_cors; then
    echo "ente-railway: bucket CORS rule set (browser uploads allowed)"
  else
    echo "ente-railway: WARNING: could not set the bucket CORS rule; web uploads will fail until it is set" >&2
    head -c 300 /tmp/cors.out 2>/dev/null >&2 || true
  fi
  rm -f /tmp/cors.out
fi

cd /
exec ./museum
