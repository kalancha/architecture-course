#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

HOST="${LOCUST_HOST:-http://localhost:8080}"
VENV_DIR="${VENV_DIR:-.venv}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [ "$#" -gt 0 ] && [[ "$1" != -* ]]; then
  HOST="$1"
  shift
fi

if [ ! -x "$VENV_DIR/bin/python" ]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

if ! "$VENV_DIR/bin/python" -m locust --version >/dev/null 2>&1; then
  "$VENV_DIR/bin/python" -m pip install --upgrade pip
  "$VENV_DIR/bin/python" -m pip install -r requirements.txt
fi

exec "$VENV_DIR/bin/python" -m locust -f Task2/locustfile.py --host="$HOST" "$@"
