#!/bin/bash
# Install Flutter SDK
echo "Cloning Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Enabling Flutter Web..."
flutter config --enable-web --no-analytics

echo "Disabling Dart Analytics..."
dart --disable-analytics

echo "Getting packages..."
flutter pub get

echo "Generating missing api_keys.dart file..."
mkdir -p lib/core/constants
cat <<EOF > lib/core/constants/api_keys.dart
class ApiKeys {
  static const String geminiApiKey = "${GEMINI_API_KEY}";
}
EOF

echo "Building for web..."
flutter build web --release --no-tree-shake-icons --no-source-maps --web-renderer canvaskit
