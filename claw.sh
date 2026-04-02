#!/bin/sh

set -e

if command -v podman-compose > /dev/null 2>&1; then
  COMPOSE="podman-compose"
elif command -v podman > /dev/null 2>&1; then
  COMPOSE="podman compose"
elif command -v docker > /dev/null 2>&1; then
  COMPOSE="docker compose"
else
  echo "Error: neither podman nor docker found. Please install one to continue."
  exit 1
fi

CMD="$1"

case "$CMD" in
  init)
    if [ -d "claw" ]; then
      printf "Directory 'claw' already exists. Do you want to delete it and start over? (y/N): "
      read -r response
      case "$response" in
        [yY][eE][sS]|[yY])
          ;;
        *)
          echo "Initialization cancelled."
          exit 0
          ;;
      esac
    fi
    echo "Generating config..."
    python3 scripts/config.py
    echo "Initializing..."
    $COMPOSE down claw
    rm -rf claw
    mkdir -p claw
    cp openclaw.json claw/
    $COMPOSE up -d --build claw
    ;;
  config)
    echo "Generating config..."
    python3 scripts/config.py
    if [ -f "claw/openclaw.json" ]; then
      printf "File 'claw/openclaw.json' already exists. Do you want to replace it? (y/N): "
      read -r response
      case "$response" in
        [yY][eE][sS]|[yY])
          cp openclaw.json claw/
          ;;
        *)
          echo "Config replacement cancelled."
          ;;
      esac
    elif [ -d "claw" ]; then
      cp openclaw.json claw/
    fi
    ;;
  log)
    echo "Showing logs..."
    $COMPOSE logs -f claw
    ;;
  start)
    echo "Starting..."
    $COMPOSE up -d claw
    ;;
  stop)
    echo "Stopping..."
    $COMPOSE down claw
    ;;
  restart)
    echo "Restarting..."
    $COMPOSE restart claw
    ;;
  build)
    echo "Generating config..."
    python3 scripts/config.py
    echo "Building..."
    $COMPOSE down claw
    $COMPOSE up -d --build claw
    ;;
  update)
    echo "Updating..."
    $COMPOSE down claw
    $COMPOSE up -d --build --pull always claw
    ;;
  run)
    shift
    echo "Running in container: $@"
    if [ "$#" -eq 3 ] && [ "$1" = "openclaw" ] && [ "$2" = "dashboard" ] && [ "$3" = "--no-open" ]; then
      tmpfile=$(mktemp)
      if $COMPOSE exec claw "$@" >"$tmpfile"; then
        status=0
      else
        status=$?
      fi
      sed 's#http://0\.0\.0\.0:#http://127.0.0.1:#g' "$tmpfile"
      rm -f "$tmpfile"
      exit "$status"
    fi
    $COMPOSE exec claw "$@"
    ;;
  dashboard)
    echo "Showing dashboard..."
    tmpfile=$(mktemp)
    if $COMPOSE exec claw openclaw dashboard --no-open >"$tmpfile"; then
      status=0
    else
      status=$?
    fi
    sed 's#http://0\.0\.0\.0:#http://127.0.0.1:#g' "$tmpfile"
    rm -f "$tmpfile"
    exit "$status"
    ;;
  *)
    echo "Usage: claw {init|config|log|start|stop|restart|build|update|run|dashboard}"
    exit 1
    ;;
esac
