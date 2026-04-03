#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")/.."

echo "Running HackerNewsApp Unit Tests..."
echo "===================================="

test_output_file="$(mktemp)"
trap 'rm -f "${test_output_file}"' EXIT

set +e
xcodebuild test \
    -project HackerNewsApp.xcodeproj \
    -scheme HackerNewsApp \
    -destination 'platform=macOS' \
    -only-testing:HackerNewsAppTests \
    >"${test_output_file}" 2>&1
test_exit_code=$?
set -e

grep -E "(Test suite|Test case|passed|failed|SUCCEEDED|FAILED|error:)" "${test_output_file}" || true

# Close the app after tests
pkill -x "HackerNewsApp" 2>/dev/null || true

echo ""
echo "===================================="
echo "Tests completed."

exit "${test_exit_code}"
