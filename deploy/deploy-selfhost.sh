#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.selfhost.yml"
ENV_FILE="${ENV_FILE:-${SCRIPT_DIR}/selfhost.env}"
CLEAN_REBUILD="${CLEAN_REBUILD:-false}"

print_usage() {
  echo "Usage: sh deploy/deploy-selfhost.sh [--clean]"
  echo "  --clean   stop stack, remove compose-built images, rebuild with --no-cache, then start"
}

normalize_bool() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) echo "true" ;;
    *) echo "false" ;;
  esac
}

CLEAN_REBUILD="$(normalize_bool "$CLEAN_REBUILD")"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --clean)
      CLEAN_REBUILD="true"
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      print_usage
      exit 1
      ;;
  esac
  shift
done

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
  echo "Edit this file, then rerun: sh deploy/deploy-selfhost.sh [--clean]"
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

compose_run() {
  SELFHOST_ENV_FILE="$ENV_FILE" docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

cd "$ROOT_DIR"
if [ "$CLEAN_REBUILD" = "true" ]; then
  echo "Running clean rebuild..."
  if [ "$USE_RELAY" = "true" ]; then
    compose_run --profile relay down --remove-orphans --rmi local
    docker builder prune -f >/dev/null 2>&1 || true
    compose_run --profile relay build --no-cache
    compose_run --profile relay up -d --force-recreate --remove-orphans
  else
    compose_run down --remove-orphans --rmi local
    docker builder prune -f >/dev/null 2>&1 || true
    compose_run build --no-cache
    compose_run up -d --force-recreate --remove-orphans
  fi
else
  if [ "$USE_RELAY" = "true" ]; then
    compose_run --profile relay up -d --build --remove-orphans
  else
    compose_run up -d --build --remove-orphans
  fi
fi

PORT="${APP_PORT:-8080}"
echo "World Monitor is up: http://<server-ip>:${PORT}"
if [ "$USE_RELAY" != "true" ]; then
  echo "Relay profile is disabled; AIS/OpenSky/Telegram/OREF/YouTube-live may degrade."
fi
