#!/bin/zsh
# Builds Vinylette and assembles a runnable .app bundle.
set -e
cd "$(dirname "$0")"

swift build -c release

APP=Vinylette.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Vinylette "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
cp -R Resources/en.lproj Resources/de.lproj "$APP/Contents/Resources/"
cp -R .build/release/Vinylette_Vinylette.bundle "$APP/Contents/Resources/"
codesign --force --deep --sign - "$APP"

echo "✓ Fertig! Starten mit: open $APP"
