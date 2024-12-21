#!/bin/bash
set -ex

# Debug information
echo "=== Build Environment ==="
echo "PWD: $(pwd)"
echo "HOME: $HOME"
echo "PATH: $PATH"
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"
ls -la

# Set up environment
FLUTTER_VERSION=${FLUTTER_VERSION:-"3.27.1"}
FLUTTER_HOME="$HOME/flutter"

echo "=== Downloading Flutter ==="
mkdir -p "$FLUTTER_HOME"
cd "$HOME"
wget "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
tar xf "flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
cd -

echo "=== Setting up Flutter ==="
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --version || echo "Flutter not in PATH: $PATH"

echo "=== Flutter Configuration ==="
flutter config --enable-web
flutter doctor -v

echo "=== Project Setup ==="
flutter pub get

echo "=== Building Web App ==="
flutter build web --release

echo "=== Build Output ==="
ls -la build/web || echo "Build directory not found"