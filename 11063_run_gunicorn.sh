#!/usr/bin/env bash
set -euo pipefail

: "${HOST:=0.0.0.0}"
: "${PORT:=8080}"
: "${WORKERS:=1}"

# Ensure imports work even if launched from anywhere
export PYTHONPATH="/app"

# Gunicorn expects a WSGI app object.
# We expose it by importing ui.server and reading "app".
exec gunicorn -w "$WORKERS" -b "$HOST:$PORT" "ui.server:app"
