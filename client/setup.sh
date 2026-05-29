#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Установите Flutter SDK: https://docs.flutter.dev/get-started/install"
  exit 1
fi

if [ ! -d android ]; then
  echo "Генерация платформенных проектов (iOS, Android, macOS, Windows)..."
  flutter create . \
    --project-name messenger_client \
    --org com.messenger \
    --platforms=ios,android,macos,windows
fi

flutter pub get

# HTTP для локального API (dev)
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ] && ! grep -q 'usesCleartextTraffic' "$MANIFEST"; then
  perl -i -pe 's/<application/<application android:usesCleartextTraffic="true"/' "$MANIFEST" 2>/dev/null || true
fi

echo ""
echo "Готово. Запуск:"
echo "  flutter run -d macos"
echo "  flutter run -d windows"
echo "  flutter run -d android"
echo "  flutter run -d ios"
