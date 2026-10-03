#!/usr/bin/env bash
# Build cho Render: Flutter web + NestJS. Backend phục vụ luôn bản web (backend/src/main.ts tìm
# frontend/build/web), nên một service chạy cả web lẫn API trên cùng domain.
#
# Render → Settings → Build Command:
#   Root Directory để trống:      bash scripts/render-build.sh
#   Root Directory = backend:     bash ../scripts/render-build.sh
#
# Biến môi trường tuỳ chọn:
#   FLUTTER_VERSION  tag Flutter cần dùng (mặc định trùng bản đang dev).
#   FLUTTER_HOME     nơi đặt Flutter SDK; đã có đúng bản thì không tải lại.
#   API_BASE_URL     đổi địa chỉ API của bản web (mặc định theo APP_ENV=product).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.8}"
FLUTTER_HOME="${FLUTTER_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/flutter-sdk}"

step() { printf '\n==> %s\n' "$*"; }

step "Flutter $FLUTTER_VERSION ($FLUTTER_HOME)"
if [ "$(git -C "$FLUTTER_HOME" describe --tags --exact-match 2>/dev/null || true)" != "$FLUTTER_VERSION" ]; then
  rm -rf "$FLUTTER_HOME"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
export CI=true
flutter config --no-analytics --no-cli-animations >/dev/null
flutter --version

step "Build web"
cd "$ROOT/frontend"
flutter pub get
defines=(--dart-define=APP_ENV=product)
if [ -n "${API_BASE_URL:-}" ]; then defines+=("--dart-define=API_BASE_URL=$API_BASE_URL"); fi
flutter build web --release "${defines[@]}"
test -f build/web/index.html

step "Build backend"
cd "$ROOT/backend"
npm ci --include=dev
npm run build

step "Xong: web ở frontend/build/web, backend ở backend/dist"
