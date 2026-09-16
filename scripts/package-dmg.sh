#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash build.sh
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/agentguard-dmg.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/volume" downloads
ditto -x -k "build/Agent Guard.zip" "$STAGE/volume"
ln -s /Applications "$STAGE/volume/Applications"
cp docs/INSTALL.txt "$STAGE/volume/Read Me.txt"
xattr -cr "$STAGE/volume/Agent Guard.app"
codesign --verify --deep --strict "$STAGE/volume/Agent Guard.app"
hdiutil create -volname "Agent Guard" -srcfolder "$STAGE/volume" -format UDZO -ov "downloads/AgentGuard-0.2.1-arm64.dmg"
hdiutil verify "downloads/AgentGuard-0.2.1-arm64.dmg"
if [[ -n "${AGENTGUARD_SIGN_IDENTITY:-}" ]]; then
    codesign --force --sign "$AGENTGUARD_SIGN_IDENTITY" --timestamp "downloads/AgentGuard-0.2.1-arm64.dmg"
    codesign --verify --strict "downloads/AgentGuard-0.2.1-arm64.dmg"
fi
(cd downloads && shasum -a 256 AgentGuard-0.2.1-arm64.dmg > SHA256SUMS)
echo "Created downloads/AgentGuard-0.2.1-arm64.dmg"
