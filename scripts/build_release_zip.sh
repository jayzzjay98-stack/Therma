#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="Therma"
APP_BUNDLE="${APP_NAME}.app"
INFO_PLIST="$PROJECT_ROOT/Info.plist"
APP_ICON="$PROJECT_ROOT/AppIcon.icns"
DIST_DIR="$PROJECT_ROOT/dist"
SKIP_DRY_RUN=0
VERSION=""
OUTPUT_PATH=""

usage() {
    cat <<'EOF'
Usage:
  scripts/build_release_zip.sh [--version X.Y.Z] [--output /path/to/Therma-X.Y.Z.zip] [--skip-dry-run]

What it does:
  1. Builds Therma in release mode
  2. Creates a clean Therma.app bundle in a temporary directory
  3. Removes metadata that can break in-app updates
  4. Applies ad-hoc signing and verifies the bundle
  5. Creates a release zip with Therma.app at the archive root
  6. Runs scripts/updater_dry_run.sh against the generated zip unless --skip-dry-run is used
EOF
}

log() {
    printf '[build-release-zip] %s\n' "$1"
}

fail() {
    printf '[build-release-zip] ERROR: %s\n' "$1" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            [[ $# -ge 2 ]] || fail "Missing value for --version"
            VERSION="$2"
            shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || fail "Missing value for --output"
            OUTPUT_PATH="$2"
            shift 2
            ;;
        --skip-dry-run)
            SKIP_DRY_RUN=1
            shift
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

[[ -f "$INFO_PLIST" ]] || fail "Info.plist not found at $INFO_PLIST"
[[ -x /usr/bin/ditto ]] || fail "Missing /usr/bin/ditto"
[[ -x /usr/bin/codesign ]] || fail "Missing /usr/bin/codesign"
[[ -x /usr/libexec/PlistBuddy ]] || fail "Missing /usr/libexec/PlistBuddy"

if [[ -z "$VERSION" ]]; then
    VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST" 2>/dev/null || true)"
fi
[[ -n "$VERSION" ]] || fail "Could not determine app version"

mkdir -p "$DIST_DIR"
if [[ -z "$OUTPUT_PATH" ]]; then
    OUTPUT_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.zip"
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/therma-release.XXXXXX")"
cleanup() {
    [[ -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"
}
trap cleanup EXIT

BUNDLE_PATH="$WORK_DIR/$APP_BUNDLE"
CONTENTS_PATH="$BUNDLE_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"
RESOURCES_PATH="$CONTENTS_PATH/Resources"

cd "$PROJECT_ROOT"

log "Building release binary"
swift build -c release

log "Assembling clean app bundle"
mkdir -p "$MACOS_PATH" "$RESOURCES_PATH"
/usr/bin/ditto ".build/release/$APP_NAME" "$MACOS_PATH/$APP_NAME"
/usr/bin/ditto "$INFO_PLIST" "$CONTENTS_PATH/Info.plist"

if [[ -f "$APP_ICON" ]]; then
    /usr/bin/ditto "$APP_ICON" "$RESOURCES_PATH/AppIcon.icns"
fi

printf 'APPL????' > "$CONTENTS_PATH/PkgInfo"

log "Removing bundle metadata that can break updates"
/usr/bin/find "$BUNDLE_PATH" \( -name '.DS_Store' -o -name '._*' \) -delete
/usr/bin/xattr -cr "$BUNDLE_PATH" >/dev/null 2>&1 || true

log "Applying ad-hoc signature"
/usr/bin/codesign --force --deep --sign - "$BUNDLE_PATH" >/dev/null
/usr/bin/codesign --verify --deep --strict "$BUNDLE_PATH" >/dev/null || fail "Bundle failed signature verification"

log "Creating release zip at $OUTPUT_PATH"
rm -f "$OUTPUT_PATH"
/usr/bin/ditto -c -k --keepParent --norsrc "$BUNDLE_PATH" "$OUTPUT_PATH"

if [[ "$SKIP_DRY_RUN" -eq 0 ]]; then
    log "Running updater dry-run verification"
    bash "$SCRIPT_DIR/updater_dry_run.sh" "$OUTPUT_PATH"
fi

log "Release zip ready: $OUTPUT_PATH"
