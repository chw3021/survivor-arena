#!/usr/bin/env bash
# Local Web export helper for Survivor Arena (Godot 4.7)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/web"
mkdir -p "$OUT"

echo "Exporting Web build to $OUT ..."
godot --headless --path "$ROOT" --export-release "Web" "$OUT/index.html"
echo "Done. Serve build/web or push to main for GitHub Pages."
