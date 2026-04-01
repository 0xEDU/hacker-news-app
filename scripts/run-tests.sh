#!/bin/bash

set -e

cd "$(dirname "$0")/.."

echo "Running HackerNewsApp Unit Tests..."
echo "===================================="

xcodebuild test \
    -project HackerNewsApp.xcodeproj \
    -scheme HackerNewsApp \
    -destination 'platform=macOS' \
    -only-testing:HackerNewsAppTests \
    2>&1 | grep -E "(Test suite|Test case|passed|failed|SUCCEEDED|FAILED|error:)" || true

# Close the app after tests
pkill -x "HackerNewsApp" 2>/dev/null || true

echo ""
echo "===================================="
echo "Tests completed."
