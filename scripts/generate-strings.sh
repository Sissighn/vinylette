#!/bin/zsh
# Regenerates the .lproj string tables from the single source of truth,
# Localizable.xcstrings. Never edit the .strings files by hand — CI fails
# when they drift from the catalog.
set -e
cd "$(dirname "$0")/.."

xcrun xcstringstool compile Sources/Vinylette/Resources/Localizable.xcstrings \
    --output-directory Sources/Vinylette/Resources \
    --language en \
    --language de

echo "✓ Regenerated en.lproj and de.lproj from Localizable.xcstrings"
