#!/bin/bash
set -e

APP_NAME="Therma"
APP_BUNDLE="${APP_NAME}.app"
INSTALL_DIR="/Applications"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║      🔧 Therma — Build & Install     ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Step 1: Build
echo "⏳ [1/4] Building..."
swift build -c release 2>&1 | tail -1
echo "   ✅ Build complete"

# Step 2: Create .app bundle
echo "⏳ [2/4] Creating app bundle..."
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

# Embed Sparkle.framework
mkdir -p "${APP_BUNDLE}/Contents/Frameworks"
cp -R ".build/arm64-apple-macosx/release/Sparkle.framework" "${APP_BUNDLE}/Contents/Frameworks/"

# Add rpath so the binary can find the embedded Sparkle
install_name_tool -add_rpath "@executable_path/../Frameworks" \
    "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" 2>/dev/null || true

echo "   ✅ App bundle created"

# Step 3: Install to /Applications
echo "⏳ [3/4] Installing to ${INSTALL_DIR}..."

pkill -x "${APP_NAME}" 2>/dev/null || true
sleep 0.5

if [ -w "${INSTALL_DIR}" ]; then
    rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
    cp -R "${APP_BUNDLE}" "${INSTALL_DIR}/"
else
    echo "   (requires admin password)"
    sudo rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
    sudo cp -R "${APP_BUNDLE}" "${INSTALL_DIR}/"
fi
echo "   ✅ Installed to ${INSTALL_DIR}/${APP_BUNDLE}"

# Step 4: Add to Login Items (Launch at startup)
echo "⏳ [4/4] Setting up auto-launch at login..."
osascript -e "
tell application \"System Events\"
    try
        delete login item \"Therma\"
    end try
    make login item at end with properties {path:\"${INSTALL_DIR}/${APP_BUNDLE}\", hidden:false}
end tell
" 2>/dev/null \
    && echo "   ✅ Added to Login Items (auto-start on boot)" \
    || echo "   ⚠️  Could not add to Login Items (add manually in System Settings)"

# Clean up local bundle
rm -rf "${APP_BUNDLE}"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║        ✅ Installation Complete!      ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "📍 Installed at: ${INSTALL_DIR}/${APP_BUNDLE}"
echo "🚀 Launching now..."
echo ""

open "${INSTALL_DIR}/${APP_BUNDLE}"
