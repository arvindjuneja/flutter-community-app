#!/bin/bash
set -ex

echo "Setting up environment..."
FLUTTER_VERSION=${FLUTTER_VERSION:-"3.27.1"}

echo "Downloading Flutter SDK..."
mkdir -p $HOME/flutter
wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C $HOME

echo "Adding Flutter to PATH..."
export PATH="$HOME/flutter/bin:$PATH"

echo "Verifying Flutter installation..."
flutter --version

echo "Enabling web support..."
flutter config --enable-web
flutter doctor -v

echo "Getting dependencies..."
flutter pub get

echo "Building web app..."
flutter build web --release