#!/bin/zsh
# Builds a universal macOS app bundle for Apple Silicon and Intel Macs.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Vinylette"
APP_BUNDLE="$APP_NAME.app"
ARM_SCRATCH=".build/release-arm64"
INTEL_SCRATCH=".build/release-x86_64"
ARM_PRODUCTS="$ARM_SCRATCH/arm64-apple-macosx/release"
INTEL_PRODUCTS="$INTEL_SCRATCH/x86_64-apple-macosx/release"
DSYM_PATH=".build/$APP_NAME.app.dSYM"
SIGNING_IDENTITY="${VINYLETTE_SIGNING_IDENTITY:--}"

echo "Building arm64 release…"
swift build \
    -c release \
    --triple arm64-apple-macosx \
    --scratch-path "$ARM_SCRATCH" \
    -Xswiftc -warnings-as-errors

echo "Building x86_64 release…"
swift build \
    -c release \
    --triple x86_64-apple-macosx \
    --scratch-path "$INTEL_SCRATCH" \
    -Xswiftc -warnings-as-errors

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

lipo -create \
    "$ARM_PRODUCTS/$APP_NAME" \
    "$INTEL_PRODUCTS/$APP_NAME" \
    -output "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cp Resources/Info.plist "$APP_BUNDLE/Contents/"
cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/"
cp -R Resources/en.lproj Resources/de.lproj "$APP_BUNDLE/Contents/Resources/"
cp -R "$ARM_PRODUCTS/Vinylette_Vinylette.bundle" "$APP_BUNDLE/Contents/Resources/"

rm -rf "$DSYM_PATH"
dsymutil "$APP_BUNDLE/Contents/MacOS/$APP_NAME" -o "$DSYM_PATH"

codesign_arguments=(
    --force
    --sign "$SIGNING_IDENTITY"
    --options runtime
    --entitlements Resources/Vinylette.entitlements
)
if [[ "$SIGNING_IDENTITY" != "-" ]]; then
    codesign_arguments+=(--timestamp)
fi

codesign "${codesign_arguments[@]}" "$APP_BUNDLE"

lipo "$APP_BUNDLE/Contents/MacOS/$APP_NAME" -verify_arch arm64 x86_64
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "✓ Universal app built: $APP_BUNDLE (arm64 + x86_64)"
if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    echo "  Signed ad hoc with Hardened Runtime; Gatekeeper approval is still required."
else
    echo "  Signed with: $SIGNING_IDENTITY"
fi
