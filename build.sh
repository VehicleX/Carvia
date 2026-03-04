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

echo "Generating missing firebase_options.dart file..."
cat <<EOF > lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD8g-vIbrF4ElDv8vQIAErfDiJ3q3a-Jb8',
    appId: '1:90676120528:web:e8173ea885d482153a87d5',
    messagingSenderId: '90676120528',
    projectId: 'carvia-88040',
    authDomain: 'carvia-88040.firebaseapp.com',
    storageBucket: 'carvia-88040.firebasestorage.app',
    measurementId: 'G-748VLK0MYB',
  );
}
EOF

echo "Building for web..."
flutter build web -v --release --no-tree-shake-icons --no-source-maps --web-renderer canvaskit
