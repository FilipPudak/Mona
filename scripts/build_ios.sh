#!/bin/bash
set -euo pipefail

APP_NAME="MengaCloud"
CONFIG="debug"
NO_CODESIGN="--no-codesign"
NO_CLEAN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release)
      CONFIG="release"
      shift
      ;;
    --no-clean)
      NO_CLEAN=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [options]"
      echo "  --release      Build in release mode (requires signing)"
      echo "  --no-clean     Skip 'flutter clean' for faster rebuild"
      echo "  --help, -h     Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: This script requires macOS."
  exit 1
fi

if ! command -v flutter &>/dev/null; then
  echo "Error: Flutter is not installed or not in PATH."
  exit 1
fi

if ! command -v xcodebuild &>/dev/null; then
  echo "Error: Xcode is not installed."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

VERSION=$(grep '^version: ' pubspec.yaml | sed 's/version: //' | tr -d '[:space:]')
if [[ -z "$VERSION" ]]; then
  VERSION="unknown"
fi

echo "==> $APP_NAME v$VERSION ($CONFIG, no-codesign)"
echo ""

if [[ "$NO_CLEAN" == false ]]; then
  echo "==> Cleaning..."
  flutter clean
fi

echo "==> Installing dependencies..."
flutter pub get

echo "==> Building iOS $CONFIG..."
flutter build ios --$CONFIG $NO_CODESIGN

BUILD_DIR="$PROJECT_DIR/build"
OUTPUT_NAME="${APP_NAME}-${VERSION}.ipa"
OUTPUT_PATH="$BUILD_DIR/$OUTPUT_NAME"
ARCHIVE_DIR="$BUILD_DIR/archive"

echo "==> Packaging .ipa..."

PAYLOAD="$BUILD_DIR/Payload"

if [[ -d "$PAYLOAD" ]]; then
  rm -rf "$PAYLOAD"
fi

mkdir -p "$PAYLOAD"
cp -r "$BUILD_DIR/ios/iphoneos/Runner.app" "$PAYLOAD/"

if [[ -f "$OUTPUT_PATH" ]]; then
  mkdir -p "$ARCHIVE_DIR"
  TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
  mv "$OUTPUT_PATH" "$ARCHIVE_DIR/${OUTPUT_NAME%.ipa}-$TIMESTAMP.ipa"
fi

cd "$BUILD_DIR"
zip -qr "$OUTPUT_NAME" "Payload"
rm -rf "$PAYLOAD"
cd "$PROJECT_DIR"

echo ""
echo "==> Done: $OUTPUT_PATH"
echo "==> Size: $(du -h "$OUTPUT_PATH" | cut -f1)"
open "$BUILD_DIR"
