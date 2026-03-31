#!/bin/sh
set -e

TZ_FILE="/home/node/.openclaw/timezone"

if [ -f "$TZ_FILE" ]; then
  TZ="$(cat "$TZ_FILE")"
else
  TZ="$(curl -fsS https://ipinfo.io/timezone || true)"
  if [ -z "$TZ" ]; then
    TZ="UTC"
  fi
  mkdir -p "$(dirname "$TZ_FILE")"
  echo "$TZ" > "$TZ_FILE"
fi

export TZ
echo "Using timezone: $TZ"

exec "$@"