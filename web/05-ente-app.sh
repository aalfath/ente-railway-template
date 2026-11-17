#!/bin/sh
# Fail fast with a clear message instead of serving an empty site.
set -eu
if [ ! -d "/out/${ENTE_APP:-}" ]; then
  echo "ente-railway: ENTE_APP must be one of: $(ls /out | tr '\n' ' ')" >&2
  exit 1
fi
case "${ENTE_API_ORIGIN:-}" in
  https://*|http://*) ;;
  *) echo "ente-railway: ENTE_API_ORIGIN must be the museum URL, e.g. https://YOUR-MUSEUM-DOMAIN" >&2; exit 1;;
esac
# Upstream's 90-replace script rewrites every app at each start; only ours is served.
for d in /out/*; do [ "$d" = "/out/$ENTE_APP" ] || rm -rf "$d"; done
echo "ente-railway: serving $ENTE_APP on port $PORT, API $ENTE_API_ORIGIN"
