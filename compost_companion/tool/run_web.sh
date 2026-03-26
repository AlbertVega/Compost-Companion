#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "Missing .env file."
  echo "Create one from .env.example:" 
  echo "  cp .env.example .env"
  exit 1
fi

flutter run -d web-server \
  --web-hostname=127.0.0.1 \
  --web-port=7357 \
  --dart-define-from-file=.env
