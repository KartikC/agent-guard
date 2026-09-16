#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
TASK_ROOT="$PWD"
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/agentguard-build.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT
APP_NAME="Agent Guard"
BUNDLE_ID="local.agentguard.mac"
SWIFT_FLAGS=(-O)
if [[ "${1:-}" == "--preview" ]]; then
    APP_NAME="Agent Guard Preview"
    BUNDLE_ID="local.agentguard.documentation"
    SWIFT_FLAGS+=(-D DOCS_PREVIEW)
elif [[ $# -gt 0 ]]; then
    echo "Usage: bash build.sh [--preview]" >&2
    exit 2
fi
APP="$STAGE/$APP_NAME.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build
cp Assets/AgentGuard.icns "$APP/Contents/Resources/AgentGuard.icns"
cp Vendor/ThinkingOrbsKit/LICENSE "$APP/Contents/Resources/ThinkingOrbs-LICENSE.txt"
xcrun swiftc "${SWIFT_FLAGS[@]}" Source/*.swift Vendor/ThinkingOrbsKit/*.swift \
    -o "$APP/Contents/MacOS/AgentGuard" -framework AppKit -framework SwiftUI \
    -framework LocalAuthentication -framework ApplicationServices -framework IOKit -framework Carbon \
    -target arm64-apple-macosx13.0 -module-cache-path "${TMPDIR:-/tmp}/agentguard-swift-cache"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>AgentGuard</string>
<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundleDisplayName</key><string>$APP_NAME</string>
<key>CFBundleIconFile</key><string>AgentGuard.icns</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.2.1</string>
<key>CFBundleVersion</key><string>8</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><false/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
xattr -cr "$APP"
if [[ -n "${AGENTGUARD_SIGN_IDENTITY:-}" ]]; then
    codesign --force --sign "$AGENTGUARD_SIGN_IDENTITY" --options runtime --timestamp "$APP"
    codesign -d -vv "$APP" 2>&1 | grep -q '^Authority=Developer ID Application:' || {
        echo "Release signing requires a Developer ID Application identity." >&2
        exit 1
    }
else
    codesign --force --sign - "$APP"
fi
codesign --verify --deep --strict "$APP"
# A clean archive preserves signing metadata in cloud-backed workspaces.
ditto --norsrc -c -k --keepParent "$APP" "build/$APP_NAME.zip"
ditto --norsrc "$APP" "build/$APP_NAME.app"
echo "Built arm64 app (not launched): $TASK_ROOT/build/$APP_NAME.app"
