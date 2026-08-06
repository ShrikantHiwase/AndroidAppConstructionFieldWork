#!/usr/bin/env bash
# Start emulators (if needed) then seed demo Auth + Firestore.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/functions"
if [[ ! -d node_modules ]]; then
  npm install
fi
cd "$ROOT"
export FIRESTORE_EMULATOR_HOST="${FIRESTORE_EMULATOR_HOST:-127.0.0.1:8080}"
export FIREBASE_AUTH_EMULATOR_HOST="${FIREBASE_AUTH_EMULATOR_HOST:-127.0.0.1:9099}"
export GCLOUD_PROJECT="${GCLOUD_PROJECT:-demo-rayns}"
node seed/seed_demo.js
