#!/bin/bash
# Install Flutter SDK
echo "Cloning Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Enabling Flutter Web..."
flutter config --enable-web

echo "Getting packages..."
flutter pub get

echo "Building for web..."
flutter build web --release --no-tree-shake-icons
