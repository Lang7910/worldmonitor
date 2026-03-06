# Self-Hosted Docker Deployment

This deployment runs World Monitor on your own server with:

- `web` container: static SPA + Nginx reverse proxy
- `api` container: local API runtime (`src-tauri/sidecar/local-api-server.mjs`)
- optional `relay` container: AIS/OpenSky/Telegram/OREF/YouTube relay path

## 1) Prepare env

```sh
cp deploy/selfhost.env.example deploy/selfhost.env
chmod +x deploy/deploy-selfhost.sh
```

Edit `deploy/selfhost.env`:

- set at least `APP_PORT`
- set provider keys you need
- for full live tracking, set `AISSTREAM_API_KEY` + OpenSky/Telegram/OREF related keys

## 2) One-command deploy

```sh
sh deploy/deploy-selfhost.sh
```

## 3) Update deploy

```sh
git pull
sh deploy/deploy-selfhost.sh
```

## 4) Stop

```sh
docker compose --env-file deploy/selfhost.env -f deploy/docker-compose.selfhost.yml down
```

## Notes

- `ENABLE_RELAY=auto` enables relay profile only if `AISSTREAM_API_KEY` is set.
- `LOCAL_API_CLOUD_FALLBACK=false` keeps requests local-only (no dependency on worldmonitor.app).
- `LOCAL_API_YOUTUBE_LIVE_MODE=local` enables local `api/youtube/live` handler for self-hosted mode.
