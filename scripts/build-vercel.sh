#!/bin/bash
set -e

echo "=== [Food Friend] Preparing Flutter SDK for Vercel Deployment ==="

FLUTTER_DIR="$(pwd)/_flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "==> Downloading Flutter SDK (stable branch)..."
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "==> Flutter Version:"
flutter --version

echo "==> Getting Flutter dependencies..."
flutter pub get

echo "==> Building Flutter Web (Release)..."
flutter build web --release

echo "==> Build successful! Artifacts located in build/web"
