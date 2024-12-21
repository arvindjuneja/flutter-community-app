#!/bin/bash
set -ex

echo "Current directory: $(pwd)"
echo "Environment variables:"
env

echo "Setting up environment..."
FLUTTER_VERSION=${FLUTTER_VERSION:-"3.27.1"}

echo "Creating Flutter home directory..."
FLUTTER_HOME="$HOME/flutter"
mkdir -p "$FLUTTER_HOME"

echo "Downloading Flutter SDK..."
wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
tar xf "flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -C "$HOME"

echo "Adding Flutter to PATH..."
export PATH="$FLUTTER_HOME/bin:$PATH"

echo "Verifying Flutter installation..."
which flutter
flutter --version

echo "Enabling web support..."
flutter config --enable-web
flutter doctor -v

echo "Getting dependencies..."
flutter pub get

echo "Building web app..."
flutter build web --release

echo "Build completed. Contents of build/web:"
ls -la build/web