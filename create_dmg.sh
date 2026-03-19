#!/bin/bash
set -e

APP_NAME="Therma"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
VOL_NAME="${APP_NAME} Installer"
TEMP_DMG_DIR="dmg_temp"

echo "🔨 Building ${APP_NAME} in release mode..."
swift build -c release

echo "📦 Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy release binary
cp ".build/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy app icon
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

# Copy Info.plist from project root
cp "Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

echo "💿 Creating DMG..."
rm -rf "${TEMP_DMG_DIR}"
mkdir -p "${TEMP_DMG_DIR}"
cp -R "${APP_BUNDLE}" "${TEMP_DMG_DIR}/"

# Add link to /Applications for drag-install
ln -s /Applications "${TEMP_DMG_DIR}/Applications"

# Create the DMG
rm -f "${DMG_NAME}"
hdiutil create -volname "${VOL_NAME}" -srcfolder "${TEMP_DMG_DIR}" -ov -format UDZO "${DMG_NAME}"

# Clean up
rm -rf "${TEMP_DMG_DIR}"
rm -rf "${APP_BUNDLE}"

echo "✅ DMG created successfully: ${DMG_NAME}"
