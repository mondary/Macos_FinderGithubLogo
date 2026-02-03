#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

xcodegen generate
xcodebuild -project FinderGitBadge.xcodeproj -scheme FinderGitBadge -configuration Debug build

SRC_APP="/Users/clm/Library/Developer/Xcode/DerivedData/FinderGitBadge-gbufpqbndzavhaazobycfcgopole/Build/Products/Debug/FinderGitBadge.app"
DEST_APP="$ROOT_DIR/release/FinderGitBadge.app"

rm -rf "$DEST_APP"
mkdir -p "$ROOT_DIR/release"

ditto "$SRC_APP" "$DEST_APP"
mkdir -p "$DEST_APP/Contents/Resources"
cp -f "$ROOT_DIR/src/Scripts/apply-github-folder-icons.sh" "$DEST_APP/Contents/Resources/apply-github-folder-icons.sh"
cp -f "$ROOT_DIR/src/Assets/github.png" "$DEST_APP/Contents/Resources/github.png"
chmod +x "$DEST_APP/Contents/Resources/apply-github-folder-icons.sh"

codesign --force --deep --sign - "$DEST_APP"

echo "Built: $DEST_APP"
