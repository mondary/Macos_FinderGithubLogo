#!/bin/bash
set -euo pipefail

ROOT="${1:-${HOME}/Documents}"
LOG="/tmp/FinderGitBadge.log"
CACHE_DIR="${HOME}/Library/Caches/FinderGitBadge"
ICON_SVG="$CACHE_DIR/github-folder.svg"
ICON_PNG="$CACHE_DIR/github-folder.png"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_PNG="$SCRIPT_DIR/github.png"
if [[ ! -f "$SOURCE_PNG" ]]; then
  SOURCE_PNG="$(cd "$SCRIPT_DIR/.." && pwd)/Assets/github.png"
fi

mkdir -p "$CACHE_DIR"

echo "$(date): run icon script on $ROOT" >> "$LOG"

ICON_FILE="$SOURCE_PNG"
if [[ ! -f "$ICON_FILE" ]]; then
  cat > "$ICON_SVG" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <rect x="64" y="256" width="896" height="640" rx="64" fill="#111111"/>
  <rect x="64" y="160" width="448" height="160" rx="48" fill="#1E1E1E"/>
  <circle cx="768" cy="704" r="160" fill="#FFFFFF"/>
  <text x="768" y="744" font-size="120" font-family="Helvetica, Arial, sans-serif" text-anchor="middle" fill="#111111">GH</text>
</svg>
SVG
  qlmanage -t -s 1024 -o "$CACHE_DIR" "$ICON_SVG" >/dev/null 2>&1 || true
  if [[ -f "$CACHE_DIR/github-folder.svg.png" ]]; then
    mv -f "$CACHE_DIR/github-folder.svg.png" "$ICON_PNG"
  fi
  ICON_FILE="$ICON_PNG"
fi

if [[ ! -f "$ICON_FILE" ]]; then
  echo "$(date): failed to render PNG" >> "$LOG"
  exit 1
fi

if [[ ! -d "$ROOT" ]]; then
  echo "$(date): root not found: $ROOT" >> "$LOG"
  exit 1
fi

# Find git repos by .git folder
while IFS= read -r -d '' gitdir; do
  repo="$(dirname "$gitdir")"
  if git -C "$repo" remote -v 2>/dev/null | grep -qi "github.com"; then
    /usr/bin/swift - "$ICON_FILE" "$repo" <<'SWIFT' || true
import AppKit
import Foundation

let iconPath = CommandLine.arguments[1]
let targetPath = CommandLine.arguments[2]

guard let image = NSImage(contentsOfFile: iconPath) else {
    exit(2)
}

let ok = NSWorkspace.shared.setIcon(image, forFile: targetPath, options: [])
if !ok {
    exit(3)
}
SWIFT
    echo "$(date): icon set -> $repo" >> "$LOG"
  fi
done < <(find "$ROOT" -name .git -type d -print0)

killall Finder >/dev/null 2>&1 || true
