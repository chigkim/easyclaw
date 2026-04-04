#!/bin/sh
set -e

NODE_HOME="/home/node"
OPENCLAW_HOME="$NODE_HOME/.openclaw"
OPENCLAW_BROWSER_DIR="$OPENCLAW_HOME/browser"
OPENCLAW_TMP_DIR="$OPENCLAW_HOME/tmp"
OPENCLAW_RUNTIME_TMP_DIR="/tmp/openclaw"
TZ_FILE="$OPENCLAW_HOME/timezone"
NODE_UID="$(id -u node)"
NODE_GID="$(id -g node)"

if [ "$(id -u)" -eq 0 ]; then
  mkdir -p "$OPENCLAW_HOME" "$OPENCLAW_BROWSER_DIR" "$OPENCLAW_TMP_DIR" "$OPENCLAW_RUNTIME_TMP_DIR"
  chown -R "$NODE_UID:$NODE_GID" "$OPENCLAW_HOME" "$OPENCLAW_RUNTIME_TMP_DIR"
fi

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

if [ "$(id -u)" -eq 0 ]; then
  chown "$NODE_UID:$NODE_GID" "$TZ_FILE"
fi

if [ "$(id -u)" -eq 0 ] && [ -f "/usr/share/zoneinfo/$TZ" ]; then
  ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
  echo "$TZ" > /etc/timezone
fi

export TZ
echo "Using timezone: $TZ"

if [ "$(id -u)" -eq 0 ]; then
  export HOME="$NODE_HOME"
  export USER="node"
  export LOGNAME="node"
  exec setpriv --reuid="$NODE_UID" --regid="$NODE_GID" --init-groups "$@"
fi

exec "$@"
