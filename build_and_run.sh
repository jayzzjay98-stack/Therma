#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BUNDLE="$PROJECT_ROOT/Therma.app"

echo "🔨 Building Therma (release)..."
bash "$PROJECT_ROOT/scripts/build_app_bundle.sh" --configuration release --output "$APP_BUNDLE"

echo "✅ Built ${APP_BUNDLE} successfully!"
echo ""
echo "🚀 Launching..."
open "$APP_BUNDLE"
