#!/bin/sh

set -e

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
    docker compose down claw
    rm -rf claw
    mkdir -p claw
    cp openclaw.json claw/
    docker compose up -d --build claw
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
    docker compose logs -f claw
    ;;
  start)
    echo "Starting..."
    docker compose up -d claw
    ;;
  stop)
    echo "Stopping..."
    docker compose down claw
    ;;
  restart)
    echo "Restarting..."
    docker compose restart claw
    ;;
  build)
    echo "Generating config..."
    python3 scripts/config.py
    echo "Building..."
    docker compose down claw
    docker compose up -d --build claw
    ;;
  update)
    echo "Updating..."
    docker compose down claw
    docker compose up -d --build --pull always claw
    ;;
  run)
    shift
    if [ "$#" -eq 0 ]; then
      echo "Usage: ./claw.sh run <command> [args...]"
      exit 1
    fi
    echo "Running in container: $@"
    if [ "$#" -eq 3 ] && [ "$1" = "openclaw" ] && [ "$2" = "dashboard" ] && [ "$3" = "--no-open" ]; then
      tmpfile=$(mktemp)
      if docker compose exec -u node claw "$@" >"$tmpfile"; then
        status=0
      else
        status=$?
      fi
      sed 's#http://0\.0\.0\.0:#http://127.0.0.1:#g' "$tmpfile"
      rm -f "$tmpfile"
      exit "$status"
    fi
    if [ "$#" -eq 1 ]; then
      case "$1" in
        sh|bash|ash|zsh)
          set -- "$1" -i
          ;;
      esac
    fi
    docker compose exec -u node claw "$@"
    ;;
  dashboard)
    echo "Showing dashboard..."
    tmpfile=$(mktemp)
    if docker compose exec -u node claw openclaw dashboard --no-open >"$tmpfile"; then
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
