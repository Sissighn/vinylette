#!/bin/zsh
# Builds Vinylette and assembles a runnable .app bundle.
set -e
cd "$(dirname "$0")"

swift build -c release

APP=Vinylette.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Vinylette "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
codesign --force --deep --sign - "$APP"

echo "✓ Fertig! Starten mit: open $APP"
