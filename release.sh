#!/bin/zsh
# Creates free local release artifacts: app ZIP, DMG, dSYM, and checksums.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Vinylette"
APP_BUNDLE="$APP_NAME.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)
RELEASE_BASENAME="$APP_NAME-$VERSION-macos-universal"
DIST_DIR="dist"
ZIP_PATH="$DIST_DIR/$RELEASE_BASENAME.zip"
DMG_PATH="$DIST_DIR/$RELEASE_BASENAME.dmg"
DSYM_ZIP_PATH="$DIST_DIR/$RELEASE_BASENAME.dSYM.zip"
CHECKSUM_PATH="$DIST_DIR/SHA256SUMS"
STAGING_ROOT=$(mktemp -d)

cleanup() {
    rm -rf "$STAGING_ROOT"
}
trap cleanup EXIT

./build.sh

mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH" "$DMG_PATH" "$DSYM_ZIP_PATH" "$CHECKSUM_PATH"

echo "Packaging ZIP…"
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo "Packaging DMG…"
DMG_STAGE="$STAGING_ROOT/dmg"
mkdir -p "$DMG_STAGE"
cp -R "$APP_BUNDLE" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"
hdiutil create \
    -volname "$APP_NAME $VERSION" \
    -srcfolder "$DMG_STAGE" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

echo "Packaging debug symbols…"
ditto -c -k --keepParent ".build/$APP_NAME.app.dSYM" "$DSYM_ZIP_PATH"

unzip -tq "$ZIP_PATH"
unzip -tq "$DSYM_ZIP_PATH"
hdiutil verify "$DMG_PATH" >/dev/null

(
    cd "$DIST_DIR"
    shasum -a 256 \
        "$(basename "$ZIP_PATH")" \
        "$(basename "$DMG_PATH")" \
        "$(basename "$DSYM_ZIP_PATH")" \
        > "$(basename "$CHECKSUM_PATH")"
)

echo "✓ Release artifacts created in $DIST_DIR/"
ls -lh "$ZIP_PATH" "$DMG_PATH" "$DSYM_ZIP_PATH" "$CHECKSUM_PATH"
