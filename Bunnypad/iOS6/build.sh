#!/bin/bash
set -e

# BunnyPad iOS 6 Build Script
# Supports:
# 1. Theos build (creates .deb or .ipa for iOS 6 devices)
# 2. Direct Clang compilation with legacy iPhoneOS SDK

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "=== Building BunnyPad for iOS 6 ==="

if [ -n "$THEOS" ] && [ -d "$THEOS" ]; then
    echo "Found Theos installation at $THEOS"
    make clean
    make package FINALPACKAGE=1
    echo "Build succeeded! Check packages/ directory."
    exit 0
fi

# Fallback: check for available iPhoneOS SDK or legacy clang
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || true)
echo "Using SDK: $SDK_PATH"

OUTPUT_APP="build/Bunnypad.app"
mkdir -p build "$OUTPUT_APP"

# Copy resources & plist
cp Bunnypad-iOS6-Info.plist "$OUTPUT_APP/Info.plist"
cp -r Resources/* "$OUTPUT_APP/"

echo "Copied resources and Info.plist into $OUTPUT_APP"
echo "To package for legacy iOS 6 devices, install Theos or use Xcode 4/5."
