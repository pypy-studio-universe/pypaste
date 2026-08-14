#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${TMPDIR:-/tmp}/PyPasteDerivedData"
PACKAGE_SCRATCH_PATH="${TMPDIR:-/tmp}/PyPastePackageBuild"

cd "$PROJECT_ROOT"

swift test \
    --package-path Packages/PyPasteKit \
    --scratch-path "$PACKAGE_SCRATCH_PATH"

CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/PyPasteClangCache" \
SWIFT_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/PyPasteSwiftCache" \
xcodebuild test \
    -workspace PyPaste.xcworkspace \
    -scheme PyPaste \
    -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -test-timeouts-enabled YES \
    -default-test-execution-time-allowance 30 \
    -maximum-test-execution-time-allowance 45
