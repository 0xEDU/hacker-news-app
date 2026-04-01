#!/bin/bash

set -e

cd "$(dirname "$0")/.."

if ! command -v swiftlint >/dev/null 2>&1; then
    echo "SwiftLint is not installed. Install with: brew install swiftlint"
    exit 1
fi

if [ "$1" = "--fix" ]; then
    swiftlint --fix
fi

swiftlint lint --strict
