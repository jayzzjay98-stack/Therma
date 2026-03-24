#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="Therma"
APP_BUNDLE="${APP_NAME}.app"
INFO_PLIST="$PROJECT_ROOT/Info.plist"
APP_ICON="$PROJECT_ROOT/AppIcon.icns"
CONFIGURATION="release"
OUTPUT_PATH=""

usage() {
    cat <<'EOF'
Usage:
  scripts/build_app_bundle.sh --output /path/to/Therma.app [--configuration release|debug]

Builds Therma and assembles a clean, ad-hoc signed app bundle at the requested output path.
EOF
}

log() {
    printf '[build-app-bundle] %s\n' "$1"
}

fail() {
    printf '[build-app-bundle] ERROR: %s\n' "$1" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            [[ $# -ge 2 ]] || fail "Missing value for --output"
            OUTPUT_PATH="$2"
            shift 2
            ;;
        --configuration)
            [[ $# -ge 2 ]] || fail "Missing value for --configuration"
            CONFIGURATION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            fail "Unknown argument: $1"
            ;;
    esac
done

[[ -n "$OUTPUT_PATH" ]] || fail "You must provide --output"
[[ "$CONFIGURATION" == "release" || "$CONFIGURATION" == "debug" ]] || fail "Configuration must be 'release' or 'debug'"
[[ -f "$INFO_PLIST" ]] || fail "Info.plist not found"

BUILD_FLAG=()
BUILD_DIR=".build/debug"
if [[ "$CONFIGURATION" == "release" ]]; then
    BUILD_FLAG=(-c release)
    BUILD_DIR=".build/release"
fi

BUNDLE_PATH="$OUTPUT_PATH"
CONTENTS_PATH="$BUNDLE_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"
RESOURCES_PATH="$CONTENTS_PATH/Resources"

cd "$PROJECT_ROOT"

log "Building $APP_NAME ($CONFIGURATION)"
swift build "${BUILD_FLAG[@]}"

log "Assembling bundle at $BUNDLE_PATH"
rm -rf "$BUNDLE_PATH"
mkdir -p "$MACOS_PATH" "$RESOURCES_PATH"
/usr/bin/ditto "$BUILD_DIR/$APP_NAME" "$MACOS_PATH/$APP_NAME"
/usr/bin/ditto "$INFO_PLIST" "$CONTENTS_PATH/Info.plist"

if [[ -f "$APP_ICON" ]]; then
    /usr/bin/ditto "$APP_ICON" "$RESOURCES_PATH/AppIcon.icns"
fi

printf 'APPL????' > "$CONTENTS_PATH/PkgInfo"
/usr/bin/find "$BUNDLE_PATH" \( -name '.DS_Store' -o -name '._*' \) -delete
/usr/bin/xattr -cr "$BUNDLE_PATH" >/dev/null 2>&1 || true

log "Applying ad-hoc signature"
/usr/bin/codesign --force --deep --sign - "$BUNDLE_PATH" >/dev/null
/usr/bin/codesign --verify --deep --strict "$BUNDLE_PATH" >/dev/null || fail "Bundle failed signature verification"

log "Bundle ready: $BUNDLE_PATH"
