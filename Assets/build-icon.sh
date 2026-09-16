#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
ICONSET=$(mktemp -d "${TMPDIR:-/tmp}/agentguard-icon.XXXXXX")/AgentGuard.iconset
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" AgentGuard.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    retina=$((size * 2))
    sips -z "$retina" "$retina" AgentGuard.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o AgentGuard.icns
echo "Created AgentGuard.icns (16–1024 px)."
