#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Therma"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
VOL_NAME="${APP_NAME} Installer"
TEMP_DMG_DIR="$PROJECT_ROOT/dmg_temp"
TEMP_APP_PATH="$TEMP_DMG_DIR/$APP_BUNDLE"

echo "🔨 Building ${APP_NAME} in release mode..."
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"

bash "$PROJECT_ROOT/scripts/build_app_bundle.sh" --configuration release --output "$TEMP_APP_PATH"

echo "💿 Creating DMG..."
ln -s /Applications "${TEMP_DMG_DIR}/Applications"
rm -f "$PROJECT_ROOT/$DMG_NAME"
hdiutil create -volname "${VOL_NAME}" -srcfolder "${TEMP_DMG_DIR}" -ov -format UDZO "$PROJECT_ROOT/$DMG_NAME"

rm -rf "$TEMP_DMG_DIR"

echo "✅ DMG created successfully: ${DMG_NAME}"
