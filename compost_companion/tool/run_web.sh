#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f .env ]]; then
  echo "Using .env for dart defines."
  flutter run -d web-server \
    --web-hostname=127.0.0.1 \
    --web-port=7357 \
    --dart-define-from-file=.env
else
  echo "No .env found. Running without dart-define-from-file."
  flutter run -d web-server \
    --web-hostname=127.0.0.1 \
    --web-port=7357
fi
