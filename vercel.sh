#!/usr/bin/env bash
set -euo pipefail

# Install Flutter (stable) in the build environment
if [ ! -d "flutter" ]; then
  echo "> Installing Flutter (stable) via shallow clone"
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git
fi
export PATH="$PWD/flutter/bin:$PATH"

# Show versions for debugging
flutter --version

# Install dependencies and enable web
flutter pub get
flutter config --enable-web

# Build release web bundle
flutter build web --release

# Optional: show output directory contents
ls -la build/web || true
