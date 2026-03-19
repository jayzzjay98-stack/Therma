#!/usr/bin/env bash
# notarize.sh — Sign, notarize, and staple Therma for Developer ID distribution.
#
# Prerequisites:
#   1. Xcode Command Line Tools installed
#   2. Developer ID Application certificate in Keychain
#   3. Notarytool credentials stored:
#      xcrun notarytool store-credentials "therma-notary" \
#        --apple-id "your@apple.com" \
#        --team-id "YOURTEAMID" \
#        --password "app-specific-password"
#
# Usage:
#   ./notarize.sh [path/to/Therma.app]
#
# Example:
#   ./notarize.sh .build/release/Therma.app

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
APP_PATH="${1:-.build/release/Therma.app}"
DEVELOPER_ID="${DEVELOPER_ID:-Developer ID Application: Your Name (TEAMID)}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-therma-notary}"
BUNDLE_ID="com.justkay.therma"
ZIP_PATH="/tmp/Therma_notarize.zip"

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "▶ $*"; }
err()  { echo "✗ ERROR: $*" >&2; exit 1; }
ok()   { echo "✓ $*"; }

# ── Validate ──────────────────────────────────────────────────────────────────
[[ -d "$APP_PATH" ]] || err "App not found at: $APP_PATH"
[[ "$DEVELOPER_ID" == *"Your Name"* ]] && err "Set DEVELOPER_ID env var before running."

log "App:      $APP_PATH"
log "Identity: $DEVELOPER_ID"
log "Profile:  $KEYCHAIN_PROFILE"
echo

# ── Step 1: Build release binary ──────────────────────────────────────────────
log "Building release binary (arm64)..."
swift build -c release --arch arm64
ok "Build complete"

# ── Step 2: Assemble .app bundle ──────────────────────────────────────────────
log "Assembling .app bundle..."
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"
cp .build/release/Therma "$APP_PATH/Contents/MacOS/Therma"
cp Info.plist "$APP_PATH/Contents/Info.plist"
[[ -f AppIcon.icns ]] && cp AppIcon.icns "$APP_PATH/Contents/Resources/AppIcon.icns"
ok "Bundle assembled"

# ── Step 3: Sign with hardened runtime ────────────────────────────────────────
log "Signing with hardened runtime..."
codesign \
    --force \
    --options runtime \
    --sign "$DEVELOPER_ID" \
    --identifier "$BUNDLE_ID" \
    --deep \
    --strict \
    --timestamp \
    "$APP_PATH"
ok "Signed"

# ── Step 4: Verify signature ──────────────────────────────────────────────────
log "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
ok "Signature valid"

# ── Step 5: Create ZIP for submission ─────────────────────────────────────────
log "Creating ZIP for notarization..."
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
ok "ZIP created: $ZIP_PATH"

# ── Step 6: Submit to Apple Notary Service ────────────────────────────────────
log "Submitting to Apple Notary Service (this may take a few minutes)..."
xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait \
    --timeout 600
ok "Notarization complete"

# ── Step 7: Staple ticket ─────────────────────────────────────────────────────
log "Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"
ok "Ticket stapled"

# ── Step 8: Final Gatekeeper check ────────────────────────────────────────────
log "Verifying Gatekeeper acceptance..."
spctl --assess --type execute --verbose=2 "$APP_PATH"
ok "Gatekeeper: app is accepted"

# ── Step 9: Create DMG ────────────────────────────────────────────────────────
log "Creating distributable DMG..."
DMG_PATH="Therma.dmg"
rm -f "$DMG_PATH"
hdiutil create \
    -volname "Therma" \
    -srcfolder "$APP_PATH" \
    -ov \
    -format UDZO \
    "$DMG_PATH"
ok "DMG created: $DMG_PATH"

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -f "$ZIP_PATH"

echo
echo "──────────────────────────────────────────"
echo "  Distribution ready: $DMG_PATH"
echo "──────────────────────────────────────────"
