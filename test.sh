#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
TEST_STAGE=$(mktemp -d "${TMPDIR:-/tmp}/agentguard-tests.XXXXXX")
trap 'rm -rf "$TEST_STAGE"' EXIT
xcrun swiftc Source/GuardPolicy.swift Tests/main.swift -o "$TEST_STAGE/policy-tests" -framework CoreGraphics -framework LocalAuthentication -target arm64-apple-macosx13.0 -module-cache-path "${TMPDIR:-/tmp}/agentguard-swift-cache"
"$TEST_STAGE/policy-tests"
