#!/bin/bash

# Build Release version of HackerNewsApp
# Usage: ./scripts/build-release.sh
# Options:
#   --archive    Create an xcarchive for distribution

set -e  # Exit on error

# Configuration
SCHEME="HackerNewsApp"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build/Release"
CONFIGURATION="Release"
ARCHIVE_PATH="${BUILD_DIR}/${SCHEME}.xcarchive"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
CREATE_ARCHIVE=false
for arg in "$@"; do
    case $arg in
        --archive)
            CREATE_ARCHIVE=true
            shift
            ;;
    esac
done

echo -e "${YELLOW}Building ${SCHEME} (${CONFIGURATION})...${NC}"
echo "Project directory: ${PROJECT_DIR}"
echo "Build output: ${BUILD_DIR}"
echo ""

# Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

if [ "$CREATE_ARCHIVE" = true ]; then
    echo -e "${YELLOW}Creating archive for distribution...${NC}"
    
    # Archive the app
    xcodebuild \
        -project "${PROJECT_DIR}/HackerNewsApp.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        -archivePath "${ARCHIVE_PATH}" \
        -destination 'platform=macOS' \
        archive \
        | grep -E "(Building|Compiling|Linking|error:|warning:|ARCHIVE)" || true

    if [ ${PIPESTATUS[0]} -eq 0 ] && [ -d "${ARCHIVE_PATH}" ]; then
        echo ""
        echo -e "${GREEN}Archive succeeded!${NC}"
        echo -e "Archive location: ${ARCHIVE_PATH}"
        echo ""
        echo "To export the archive, create an ExportOptions.plist and run:"
        echo "  xcodebuild -exportArchive -archivePath ${ARCHIVE_PATH} -exportPath ${BUILD_DIR} -exportOptionsPlist ExportOptions.plist"
    else
        echo -e "${RED}Archive failed!${NC}"
        exit 1
    fi
else
    # Standard release build
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
            
            # Show app size
            APP_SIZE=$(du -sh "${BUILD_DIR}/${SCHEME}.app" | cut -f1)
            echo -e "App size: ${APP_SIZE}"
        else
            echo -e "${RED}Build completed but app not found at expected location${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Build failed!${NC}"
        exit 1
    fi
fi
