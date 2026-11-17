[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/ente-1?utm_medium=integration&utm_source=button&utm_campaign=ente)

# Ente on Railway

A Railway template for [Ente](https://github.com/ente-io/ente), the open-source, end-to-end encrypted photo storage (an alternative to Google Photos and iCloud Photos). The same server also works with the Ente Auth 2FA app.

## What it deploys

| Service | Built from | What it does |
|---|---|---|
| `Museum` | `museum/` in this repo, `ghcr.io/ente/server` | Ente's API server. Public URL, health check `/ping` |
| `Photos` | `web/` in this repo, `ghcr.io/ente/web` | The Ente Photos web app |
| `Albums` | `web/` in this repo, `ghcr.io/ente/web` | Public album links you share with others |
| `Postgres` | Railway's Postgres 18 | Accounts, metadata, on a volume |
| `Storage` | Railway Bucket (S3) | Your encrypted photos and videos |

Versions: server image commit `c2e571c5` (2026-11-15), web image commit `482ae68e` (2026-11-11, includes Photos web 1.3.70). Upstream publishes these images only as `latest` and one tag per git commit, so the Dockerfiles pin the commit tag **and** its digest.

## Variables

All variables are filled in for you; the template asks for nothing.

- `Museum`: `MUSEUM_ENCRYPTION_KEY_HEX`, `MUSEUM_HASH_KEY_HEX`, `MUSEUM_JWT_SECRET_HEX` are generated per deployment (`${{secret(...)}}`). The start script turns them into the base64 keys museum needs, and museum refuses to start without them, so it never runs on the sample keys from upstream's `local.yaml`. **Keep them**: they encrypt stored email addresses and sign sessions. Database and bucket settings are references to `Postgres` and `Storage`.
- `Photos`, `Albums`: `ENTE_APP` (which app to serve), `ENTE_API_ORIGIN` (the museum URL), `PORT`.

Any other museum setting can be added as an `ENTE_…` variable: museum maps config keys to variables by upper-casing them and turning `.` and `-` into `_` (for example `internal.disable-registration` → `ENTE_INTERNAL_DISABLE_REGISTRATION=true`, SMTP via `ENTE_SMTP_HOST`, `ENTE_SMTP_PORT`, `ENTE_SMTP_USERNAME`, `ENTE_SMTP_PASSWORD`, `ENTE_SMTP_EMAIL`). See upstream's [configuration reference](https://ente.com/help/self-hosting/installation/config).

## After deploy

1. Open the `Photos` URL and choose **Don't have an account?** to sign up. The first account becomes the admin.
2. Without SMTP, Ente doesn't send the verification email: find the 6-digit code in the `Museum` deploy logs (`Verification code: 123456`). Strangers can't finish signing up for the same reason.
3. Mobile and desktop apps: on the first screen tap 7 times (or open the developer settings), enter the `Museum` URL as the server endpoint, then log in.
4. New accounts get 10 GB. To raise it, use the [Ente CLI admin commands](https://ente.com/help/self-hosting/administration/users).

## Updates

Every service here builds from this repository. When we bump the pinned images, the change lands on `main` with a `CHANGELOG.md` entry, and Railway shows you an "update available" notice. Read the changelog, then apply it when it suits you. Back up `Postgres` first.

## Files

- `museum/Dockerfile`, `museum/start.sh`: pinned server image and a small start script (keys, port, defaults).
- `web/Dockerfile`, `web/default.conf.template`, `web/05-ente-app.sh`: pinned web image, one app per service on `$PORT`.
- `CHANGELOG.md`: what changed in each version.

Ente is © Ente Technologies, AGPL-3.0. This repo only holds the Railway wrapper.
