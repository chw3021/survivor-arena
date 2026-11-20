#!/usr/bin/env bash
# Local Web export helper for Survivor Arena (Godot 4.7)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/web"
mkdir -p "$OUT"

echo "Exporting Web build to $OUT ..."
godot --headless --path "$ROOT" --export-release "Web" "$OUT/index.html"
mv -f "$OUT/index.html" "$OUT/play.html"
cp "$ROOT/site/index.html" "$OUT/index.html"
mkdir -p "$OUT/docs"
cp -r "$ROOT/site/docs/." "$OUT/docs/"
# HTML5 BGM outside PCK
mkdir -p "$OUT/bgm"
cp -f "$ROOT/assets/bgm/"*.wav "$OUT/bgm/"
echo "Done. Hub/play/docs/bgm assembled under build/web."
