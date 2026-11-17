# Ente server ("museum"). Upstream publishes this image only as `latest` and
# one tag per git commit, so we pin the commit tag that `latest` pointed to,
# plus its digest. Bump both together (see CHANGELOG.md).
FROM ghcr.io/ente/server:c2e571c599222ef6f8349dcc638bf23e0d885e21@sha256:f8c33e9bc1d5b7079dcda51522dd9f4fb28d93bef8655d95be54a978acc43408

# curl signs the one-time bucket CORS request in start.sh (--aws-sigv4).
RUN apk add --no-cache curl

COPY --chmod=755 start.sh /usr/local/bin/ente-railway-start

EXPOSE 8080
CMD ["/usr/local/bin/ente-railway-start"]
