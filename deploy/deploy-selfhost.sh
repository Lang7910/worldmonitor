#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.selfhost.yml"
ENV_FILE="${ENV_FILE:-${SCRIPT_DIR}/selfhost.env}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose plugin is required"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  cp "${SCRIPT_DIR}/selfhost.env.example" "$ENV_FILE"
  echo "Created ${ENV_FILE}"
  echo "Edit this file, then rerun: sh deploy/deploy-selfhost.sh"
  exit 1
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

ENABLE_RELAY_VALUE="${ENABLE_RELAY:-auto}"
USE_RELAY="false"
if [ "$ENABLE_RELAY_VALUE" = "true" ]; then
  USE_RELAY="true"
elif [ "$ENABLE_RELAY_VALUE" = "auto" ] && [ -n "${AISSTREAM_API_KEY:-}" ]; then
  USE_RELAY="true"
fi

cd "$ROOT_DIR"
if [ "$USE_RELAY" = "true" ]; then
  SELFHOST_ENV_FILE="$ENV_FILE" docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" --profile relay up -d --build --remove-orphans
else
  SELFHOST_ENV_FILE="$ENV_FILE" docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --build --remove-orphans
fi

PORT="${APP_PORT:-8080}"
echo "World Monitor is up: http://<server-ip>:${PORT}"
if [ "$USE_RELAY" != "true" ]; then
  echo "Relay profile is disabled; AIS/OpenSky/Telegram/OREF/YouTube-live may degrade."
fi
