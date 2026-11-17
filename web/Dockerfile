# Ente web apps (Photos, Albums, Auth, ...), served by nginx. One image, one
# app per Railway service: ENTE_APP picks the app, PORT the listen port.
# Upstream publishes this image only as `latest` and one tag per git commit,
# so we pin the commit tag that `latest` pointed to, plus its digest.
FROM ghcr.io/ente/web:482ae68e9b38dba12bc808741464373c68778081@sha256:f135d345510d9f85545960543961a7b6cd0b78d20e004704a2a0165b7692f3ef

ENV PORT=3000 \
    ENTE_APP=photos

# Replaces upstream's multi-port server block: one app on $PORT.
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY --chmod=755 05-ente-app.sh /docker-entrypoint.d/05-ente-app.sh

EXPOSE 3000
