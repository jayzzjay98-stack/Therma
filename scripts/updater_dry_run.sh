#!/bin/bash
set -euo pipefail

APP_BUNDLE_NAME="Therma.app"
KEEP_WORKDIR=0
SELF_TEST=0
ZIP_PATH=""

usage() {
    cat <<'EOF'
Usage:
  scripts/updater_dry_run.sh <path-to-release-zip> [--keep-workdir]
  scripts/updater_dry_run.sh --self-test

What it does:
  1. Extracts the release zip with ditto
  2. Locates a single Therma.app bundle
  3. Removes AppleDouble and Finder metadata files
  4. Validates Info.plist and executable presence
  5. Verifies the bundle signature, ad-hoc signing if needed
  6. Stages the bundle into a temporary install root without touching /Applications
EOF
}

log() {
    printf '[updater-dry-run] %s\n' "$1"
}

fail() {
    printf '[updater-dry-run] ERROR: %s\n' "$1" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

cleanup_paths=()

cleanup() {
    if [[ "${KEEP_WORKDIR}" -eq 1 ]]; then
        return
    fi

    local path
    for path in "${cleanup_paths[@]:-}"; do
        [[ -n "$path" && -e "$path" ]] && rm -rf "$path"
    done
}

trap cleanup EXIT

make_temp_dir() {
    mktemp -d "${TMPDIR:-/tmp}/therma-updater.XXXXXX"
}

create_self_test_zip() {
    local root bundle plist macos zip_path
    root="$(make_temp_dir)"
    cleanup_paths+=("$root")

    bundle="$root/$APP_BUNDLE_NAME"
    plist="$bundle/Contents/Info.plist"
    macos="$bundle/Contents/MacOS"
    zip_path="$root/Therma-self-test.zip"

    mkdir -p "$macos"
    /bin/cp /usr/bin/true "$macos/Therma"
    chmod +x "$macos/Therma"

    cat > "$plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Therma</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.therma.selftest</string>
    <key>CFBundleName</key>
    <string>Therma</string>
</dict>
</plist>
EOF

    printf 'junk' > "$bundle/Contents/._Info.plist"
    /usr/bin/ditto -c -k --keepParent "$bundle" "$zip_path"
    printf '%s\n' "$zip_path"
}

find_app_bundle() {
    local root="$1"
    local matches=()
    while IFS= read -r path; do
        matches+=("$path")
    done < <(/usr/bin/find "$root" -type d -name '*.app' | sort)

    [[ "${#matches[@]}" -gt 0 ]] || fail "No app bundle found in extracted archive"

    local exact=()
    local path
    for path in "${matches[@]}"; do
        if [[ "$(basename "$path")" == "$APP_BUNDLE_NAME" ]]; then
            exact+=("$path")
        fi
    done

    if [[ "${#exact[@]}" -eq 1 ]]; then
        printf '%s\n' "${exact[0]}"
        return
    fi

    if [[ "${#exact[@]}" -gt 1 ]]; then
        fail "Found multiple $APP_BUNDLE_NAME bundles in extracted archive"
    fi

    if [[ "${#matches[@]}" -eq 1 ]]; then
        printf '%s\n' "${matches[0]}"
        return
    fi

    fail "Found multiple app bundles and could not determine the correct one"
}

sanitize_bundle() {
    local bundle="$1"
    /usr/bin/find "$bundle" \( -name '.DS_Store' -o -name '._*' \) -delete
}

validate_bundle_structure() {
    local bundle="$1"
    local plist executable_name executable_path

    [[ "$(basename "$bundle")" == "$APP_BUNDLE_NAME" ]] || fail "Expected bundle name $APP_BUNDLE_NAME, got $(basename "$bundle")"

    plist="$bundle/Contents/Info.plist"
    [[ -f "$plist" ]] || fail "Missing Info.plist in bundle"

    executable_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist" 2>/dev/null || true)"
    [[ -n "$executable_name" ]] || fail "CFBundleExecutable is missing from Info.plist"

    executable_path="$bundle/Contents/MacOS/$executable_name"
    [[ -f "$executable_path" ]] || fail "Executable $executable_name is missing from bundle"
}

verify_or_sign_bundle() {
    local bundle="$1"
    /usr/bin/xattr -rd com.apple.quarantine "$bundle" >/dev/null 2>&1 || true
    if /usr/bin/codesign --verify --deep --strict "$bundle" >/dev/null 2>&1; then
        log "Signature verified"
        return
    fi

    log "Signature verification failed, applying ad-hoc signature"
    /usr/bin/codesign --force --deep --sign - "$bundle" >/dev/null
    /usr/bin/codesign --verify --deep --strict "$bundle" >/dev/null || fail "Bundle failed codesign verification after ad-hoc signing"
}

stage_bundle() {
    local bundle="$1"
    local stage_root staged
    stage_root="$(make_temp_dir)"
    cleanup_paths+=("$stage_root")
    staged="$stage_root/$APP_BUNDLE_NAME"

    /usr/bin/ditto "$bundle" "$staged"
    /usr/bin/codesign --verify --deep --strict "$staged" >/dev/null || fail "Staged bundle failed signature verification"
    printf '%s\n' "$stage_root"
}

run_dry_run() {
    local zip_path="$1"
    local extract_root app_bundle stage_root

    [[ -f "$zip_path" ]] || fail "Zip file not found: $zip_path"

    extract_root="$(make_temp_dir)"
    cleanup_paths+=("$extract_root")

    log "Extracting $(basename "$zip_path")"
    /usr/bin/ditto -x -k --noqtn "$zip_path" "$extract_root"

    app_bundle="$(find_app_bundle "$extract_root")"
    log "Found app bundle: $app_bundle"

    sanitize_bundle "$app_bundle"
    validate_bundle_structure "$app_bundle"
    verify_or_sign_bundle "$app_bundle"

    stage_root="$(stage_bundle "$app_bundle")"
    log "Dry-run staging succeeded"
    log "Staged bundle root: $stage_root"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --self-test)
            SELF_TEST=1
            shift
            ;;
        --keep-workdir)
            KEEP_WORKDIR=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            [[ -z "$ZIP_PATH" ]] || fail "Unexpected argument: $1"
            ZIP_PATH="$1"
            shift
            ;;
    esac
done

require_command /usr/bin/ditto
require_command /usr/bin/codesign
require_command /usr/bin/find
require_command /usr/bin/xattr
require_command /usr/libexec/PlistBuddy

if [[ "$SELF_TEST" -eq 1 ]]; then
    ZIP_PATH="$(create_self_test_zip)"
    log "Created synthetic self-test archive at $ZIP_PATH"
fi

[[ -n "$ZIP_PATH" ]] || {
    usage
    exit 1
}

run_dry_run "$ZIP_PATH"
log "Updater dry-run completed successfully"
