#!/bin/bash

# Build Debug version of HackerNewsApp
# Usage: ./scripts/build-debug.sh

set -e  # Exit on error

# Configuration
SCHEME="HackerNewsApp"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build/Debug"
CONFIGURATION="Debug"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building ${SCHEME} (${CONFIGURATION})...${NC}"
echo "Project directory: ${PROJECT_DIR}"
echo "Build output: ${BUILD_DIR}"
echo ""

# Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Build the app
xcodebuild \
    -project "${PROJECT_DIR}/HackerNewsApp.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    -destination 'platform=macOS' \
    build \
    | grep -E "(Building|Compiling|Linking|error:|warning:|BUILD)" || true

# Check if build succeeded
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    # Copy the app to build directory
    APP_PATH="${BUILD_DIR}/DerivedData/Build/Products/${CONFIGURATION}/${SCHEME}.app"
    if [ -d "${APP_PATH}" ]; then
        cp -R "${APP_PATH}" "${BUILD_DIR}/"
        echo ""
        echo -e "${GREEN}Build succeeded!${NC}"
        echo -e "App location: ${BUILD_DIR}/${SCHEME}.app"
    else
        echo -e "${RED}Build completed but app not found at expected location${NC}"
        exit 1
    fi
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi
