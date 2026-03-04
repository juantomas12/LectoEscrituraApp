#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_BIN="${ROOT_DIR}/flutter-local"
BUILD_DIR="${ROOT_DIR}/build/web"
DEPLOY_DIR="/var/www/juan/lectorEscrituraapp"
BASE_HREF="/lectorEscrituraapp/"

cd "${ROOT_DIR}"

echo "[1/5] flutter pub get"
"${FLUTTER_BIN}" pub get

echo "[2/5] flutter analyze"
"${FLUTTER_BIN}" analyze

echo "[3/5] flutter test"
"${FLUTTER_BIN}" test

echo "[4/5] flutter build web --release --base-href ${BASE_HREF}"
"${FLUTTER_BIN}" build web --release --base-href "${BASE_HREF}"

echo "[5/5] deploy -> ${DEPLOY_DIR}"
mkdir -p "${DEPLOY_DIR}"
rsync -a --delete "${BUILD_DIR}/" "${DEPLOY_DIR}/"

echo "OK: publicado en https://iaprende.itacaflow.com/lectorEscrituraapp/"
