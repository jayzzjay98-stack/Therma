#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Therma"
APP_BUNDLE="${APP_NAME}.app"
INSTALL_DIR="/Applications"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/therma-install.XXXXXX")"
LOCAL_APP_PATH="$WORK_DIR/$APP_BUNDLE"

cleanup() {
    [[ -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"
}

trap cleanup EXIT

echo ""
echo "╔══════════════════════════════════════╗"
echo "║      🔧 Therma — Build & Install     ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Step 1: Build
echo "⏳ [1/4] Building clean app bundle..."
bash "$PROJECT_ROOT/scripts/build_app_bundle.sh" --configuration release --output "$LOCAL_APP_PATH"
echo "   ✅ Build complete"

# Step 3: Install to /Applications
echo "⏳ [2/4] Installing to ${INSTALL_DIR}..."

pkill -x "${APP_NAME}" 2>/dev/null || true
sleep 0.5

if [ -w "${INSTALL_DIR}" ]; then
    rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
    /usr/bin/ditto "$LOCAL_APP_PATH" "${INSTALL_DIR}/${APP_BUNDLE}"
else
    echo "   (requires admin password)"
    sudo rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
    sudo /usr/bin/ditto "$LOCAL_APP_PATH" "${INSTALL_DIR}/${APP_BUNDLE}"
fi
echo "   ✅ Installed to ${INSTALL_DIR}/${APP_BUNDLE}"

# Step 4: Add to Login Items (Launch at startup)
echo "⏳ [3/4] Setting up auto-launch at login..."
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

echo "⏳ [4/4] Verifying installed bundle..."
/usr/bin/codesign --verify --deep --strict "${INSTALL_DIR}/${APP_BUNDLE}" >/dev/null \
    && echo "   ✅ Installed bundle verified" \
    || echo "   ⚠️  Installed bundle could not be verified"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║        ✅ Installation Complete!      ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "📍 Installed at: ${INSTALL_DIR}/${APP_BUNDLE}"
echo "🚀 Launching now..."
echo ""

open "${INSTALL_DIR}/${APP_BUNDLE}"
