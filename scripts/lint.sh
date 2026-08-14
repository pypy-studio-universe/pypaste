#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT"
xcrun swift-format lint \
    --configuration .swift-format \
    --recursive \
    --parallel \
    --strict \
    App Packages Tests

if ! command -v swiftlint >/dev/null 2>&1; then
    echo "error: SwiftLint is required. Install it with: brew install swiftlint" >&2
    exit 1
fi

swiftlint lint --strict --no-cache --config .swiftlint.yml
