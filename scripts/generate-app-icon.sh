#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SVG_PATH="$ROOT_DIR/App/AppIcon.svg"
OUTPUT_PATH="${1:-$ROOT_DIR/App/AppIcon.icns}"
TMP_DIR="$(mktemp -d)"
ICONSET_DIR="$TMP_DIR/AppIcon.iconset"
RENDERED_PNG="$TMP_DIR/$(basename "$SVG_PATH").png"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

if [[ ! -f "$SVG_PATH" ]]; then
    echo "Missing SVG source: $SVG_PATH" >&2
    exit 1
fi

mkdir -p "$ICONSET_DIR" "$(dirname "$OUTPUT_PATH")"

qlmanage -t -s 1024 -o "$TMP_DIR" "$SVG_PATH" >/dev/null 2>&1

if [[ ! -f "$RENDERED_PNG" ]]; then
    echo "Failed to render PNG preview from $SVG_PATH" >&2
    exit 1
fi

render_icon() {
    local size="$1"
    local name="$2"
    sips -z "$size" "$size" "$RENDERED_PNG" --out "$ICONSET_DIR/$name" >/dev/null
}

render_icon 16 icon_16x16.png
render_icon 32 icon_16x16@2x.png
render_icon 32 icon_32x32.png
render_icon 64 icon_32x32@2x.png
render_icon 128 icon_128x128.png
render_icon 256 icon_128x128@2x.png
render_icon 256 icon_256x256.png
render_icon 512 icon_256x256@2x.png
render_icon 512 icon_512x512.png
render_icon 1024 icon_512x512@2x.png

iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_PATH"

echo "Generated app icon:"
echo "$OUTPUT_PATH"
