#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT"
xcrun swift-format format \
    --configuration .swift-format \
    --in-place \
    --recursive \
    --parallel \
    App Packages Tests
