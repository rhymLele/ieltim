#!/usr/bin/env bash
# Build trên Render.
#
#   bash scripts/render-build.sh web   → chỉ build Flutter web (Static Site; Publish Directory: frontend/build/web)
#   bash scripts/render-build.sh       → web + NestJS (một Web Service phục vụ cả web lẫn API, xem backend/src/main.ts)
#
# Static Site còn cần luật Rewrite  /*  →  /index.html  (Redirects/Rewrites), nếu không mở thẳng /home sẽ 404.
#
# Biến môi trường tuỳ chọn:
#   FLUTTER_VERSION  tag Flutter cần dùng (mặc định trùng bản đang dev).
#   FLUTTER_DIR      nơi đặt Flutter SDK (mặc định ~/.cache/flutter-<version>); đã có thì không tải lại.
#   API_BASE_URL     đổi địa chỉ API của bản web (mặc định theo APP_ENV=product).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-all}"
case "$TARGET" in web | all) ;; *) echo "Dùng: render-build.sh [web|all]" >&2; exit 2 ;; esac
FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.8}"
FLUTTER_DIR="${FLUTTER_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/flutter-$FLUTTER_VERSION}"

step() { printf '\n==> %s\n' "$*"; }

step "Flutter $FLUTTER_VERSION ($FLUTTER_DIR)"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  if [ -e "$FLUTTER_DIR" ]; then
    echo "$FLUTTER_DIR có sẵn nhưng không phải Flutter SDK. Xoá thư mục đó hoặc đặt FLUTTER_DIR khác." >&2
    exit 1
  fi
  # Tải vào thư mục tạm rồi mới đổi tên: build bị ngắt giữa chừng không để lại SDK hỏng.
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  rm -rf "$FLUTTER_DIR.partial"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR.partial"
  mv "$FLUTTER_DIR.partial" "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
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

if [ "$TARGET" = web ]; then
  step "Xong: web ở frontend/build/web"
  exit 0
fi

step "Build backend"
cd "$ROOT/backend"
npm ci --include=dev
npm run build

step "Xong: web ở frontend/build/web, backend ở backend/dist"
