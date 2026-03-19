#!/bin/bash
set -e

APP_NAME="Therma"
INSTALL_DIR="/Applications"
APP_BUNDLE="${APP_NAME}.app"
SUDOERS_PATTERN="/private/etc/sudoers.d/therma_*"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║       🗑️  Therma — Uninstall         ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Step 1: Quit running instance
echo "⏳ [1/4] Stopping Therma..."
pkill -x "${APP_NAME}" 2>/dev/null && echo "   ✅ Stopped" || echo "   ℹ️  Not running"

# Step 2: Remove Login Item
echo "⏳ [2/4] Removing from Login Items..."
osascript -e "
tell application \"System Events\"
    try
        delete login item \"Therma\"
        return \"removed\"
    on error
        return \"not found\"
    end try
end tell
" 2>/dev/null && echo "   ✅ Removed from Login Items" || echo "   ℹ️  Not in Login Items"

# Step 3: Remove app bundle
echo "⏳ [3/4] Removing app from ${INSTALL_DIR}..."
if [ -d "${INSTALL_DIR}/${APP_BUNDLE}" ]; then
    if [ -w "${INSTALL_DIR}" ]; then
        rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
    else
        sudo rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
    fi
    echo "   ✅ Removed ${INSTALL_DIR}/${APP_BUNDLE}"
else
    echo "   ℹ️  App not found at ${INSTALL_DIR}/${APP_BUNDLE}"
fi

# Step 4: Remove sudoers drop-in file
echo "⏳ [4/4] Removing sudoers rule..."
SUDOERS_FILES=$(sudo ls ${SUDOERS_PATTERN} 2>/dev/null || true)
if [ -n "${SUDOERS_FILES}" ]; then
    sudo rm -f ${SUDOERS_PATTERN}
    echo "   ✅ Removed sudoers rule: ${SUDOERS_FILES}"
else
    echo "   ℹ️  No sudoers rule found (already clean)"
fi

echo ""
echo "╔══════════════════════════════════════╗"
echo "║        ✅ Uninstall Complete!         ║"
echo "╚══════════════════════════════════════╝"
echo ""
