#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

SRC_BG_SVG="${SRC_BG_SVG:-${SCRIPT_DIR}/background.svg}"
SRC_FG_SVG="${SRC_FG_SVG:-${SCRIPT_DIR}/foreground.svg}"

SRC_SVG="${SRC_SVG:-${SCRIPT_DIR}/app_icon.svg}"
SRC_SVG_ROUNDED="${SRC_SVG_ROUNDED:-${SCRIPT_DIR}/app_icon_rounded.svg}"
SRC_MASKABLE_SVG="${SRC_MASKABLE_SVG:-${SCRIPT_DIR}/app_icon_maskable.svg}"

SRC_ANDROID_ADAPTIVE_BG_SVG="${SRC_ANDROID_ADAPTIVE_BG_SVG:-${SRC_BG_SVG}}"
SRC_ANDROID_ADAPTIVE_FG_SVG="${SRC_ANDROID_ADAPTIVE_FG_SVG:-${SRC_FG_SVG}}"

TMP_ROOT="${TMP_ROOT:-${ROOT_DIR}/.tmp/icon-build}"
OUT_DIR="${OUT_DIR:-${SCRIPT_DIR}/out}"

usage() {
  cat <<'EOF'
Usage:
  resources/icon/update_icons.sh

Env:
  SRC_BG_SVG=resources/icon/background.svg
  SRC_FG_SVG=resources/icon/foreground.svg
  SRC_SVG=resources/icon/app_icon.svg
  SRC_SVG_ROUNDED=resources/icon/app_icon_rounded.svg
  SRC_MASKABLE_SVG=resources/icon/app_icon_maskable.svg
  SRC_ANDROID_ADAPTIVE_BG_SVG=resources/icon/background.svg
  SRC_ANDROID_ADAPTIVE_FG_SVG=resources/icon/foreground.svg
  OUT_DIR=resources/icon/out

Notes:
  - Prefers ImageMagick for best transparency support.
  - Falls back to inkscape/rsvg-convert if available.
  - Generates app_icon.svg/app_icon_rounded.svg/app_icon_maskable.svg from background.svg+foreground.svg.
  - Overwrites platform icon files in-place.
EOF
}

have() { command -v "$1" >/dev/null 2>&1; }

generate_svgs() {
  python3 - "$SRC_BG_SVG" "$SRC_FG_SVG" "$SRC_SVG" "$SRC_SVG_ROUNDED" "$SRC_MASKABLE_SVG" <<'PY'
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

bg_path, fg_path, out_merged, out_rounded, out_maskable = map(Path, sys.argv[1:6])

def strip_ns(tag: str) -> str:
  return tag.rsplit("}", 1)[-1] if "}" in tag else tag

def parse(svg_path: Path) -> ET.Element:
  root = ET.parse(svg_path).getroot()
  root.tag = strip_ns(root.tag)
  for el in root.iter():
    el.tag = strip_ns(el.tag)
  return root

bg = parse(bg_path)
fg = parse(fg_path)

def get_size(root: ET.Element) -> tuple[str, str, str]:
  w = (root.get("width") or "1024").replace("px", "")
  h = (root.get("height") or "1024").replace("px", "")
  vb = root.get("viewBox") or f"0 0 {w} {h}"
  return w, h, vb

w, h, vb = get_size(bg)

merged = ET.Element("svg", {"width": w, "height": h, "viewBox": vb, "xmlns": "http://www.w3.org/2000/svg"})

defs = ET.SubElement(merged, "defs")
def add_defs(src: ET.Element):
  for child in list(src):
    if child.tag == "defs":
      for d in list(child):
        defs.append(d)
add_defs(bg)
add_defs(fg)
if len(defs) == 0:
  merged.remove(defs)

def add_children(dst: ET.Element, src: ET.Element):
  for child in list(src):
    if child.tag == "defs":
      continue
    dst.append(child)

add_children(merged, bg)
add_children(merged, fg)

def write_svg(path: Path, root: ET.Element):
  path.write_text('<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(root, encoding="unicode"), encoding="utf-8")

write_svg(out_merged, merged)
write_svg(out_maskable, merged)

# Rounded wrapper: transparent outside the clip (matches lcr).
rounded = ET.Element("svg", {"width": w, "height": h, "viewBox": vb, "xmlns": "http://www.w3.org/2000/svg"})
defs2 = ET.SubElement(rounded, "defs")
clip = ET.SubElement(defs2, "clipPath", {"id": "clip"})
ET.SubElement(clip, "rect", {"x": "64", "y": "64", "width": "896", "height": "896", "rx": "220"})
g = ET.SubElement(rounded, "g", {"clip-path": "url(#clip)"})
for child in list(merged):
  if child.tag == "defs":
    continue
  g.append(child)
write_svg(out_rounded, rounded)
PY
}

render_png() {
  local svg="$1"
  local size="$2"
  local out="$3"

  mkdir -p "$(dirname "$out")"
  mkdir -p "$TMP_ROOT"
  local tmpdir
  tmpdir="$(mktemp -d "${TMP_ROOT}/render.XXXXXX")"
  trap 'rm -rf "$tmpdir"' RETURN

  local tmp_png="${tmpdir}/render.png"

  if have magick; then
    magick -background none -density 300 "$svg" -resize "${size}x${size}" -alpha on -define png:format=png32 "$tmp_png"
  elif have convert; then
    convert -background none -density 300 "$svg" -resize "${size}x${size}" -alpha on -define png:format=png32 "$tmp_png"
  elif have inkscape; then
    inkscape "$svg" --export-type=png --export-filename="$tmp_png" --export-background-opacity=0 -w "$size" -h "$size" >/dev/null
  elif have rsvg-convert; then
    rsvg-convert --background-color=none -w "$size" -h "$size" -o "$tmp_png" "$svg"
  else
    echo "No SVG renderer found. Install one of: ImageMagick / Inkscape / librsvg." >&2
    exit 1
  fi

  mv -f "$tmp_png" "$out"
  trap - RETURN
  rm -rf "$tmpdir"
}

render_set_from_contents_json() {
  local svg="$1"
  local contents_json="$2"
  local out_dir="$3"

  python3 - "$contents_json" <<'PY' | while IFS=$'\t' read -r filename px; do
import json, sys
from decimal import Decimal, ROUND_HALF_UP

path = sys.argv[1]
data = json.load(open(path, "r", encoding="utf-8"))

for img in data.get("images", []):
    fn = img.get("filename")
    if not fn:
        continue
    size_str = (img.get("size") or "").split("x")[0]
    scale_str = (img.get("scale") or "1x").rstrip("x")
    px = (Decimal(size_str) * Decimal(scale_str)).quantize(Decimal("1"), rounding=ROUND_HALF_UP)
    print(f"{fn}\t{int(px)}")
PY
    render_png "$svg" "$px" "${out_dir}/${filename}"
  done
}

update_android() {
  # Legacy launcher icon (pre-Android 8.0 or when adaptive not used).
  render_png "$SRC_SVG_ROUNDED" 48  "${ROOT_DIR}/android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
  render_png "$SRC_SVG_ROUNDED" 72  "${ROOT_DIR}/android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
  render_png "$SRC_SVG_ROUNDED" 96  "${ROOT_DIR}/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
  render_png "$SRC_SVG_ROUNDED" 144 "${ROOT_DIR}/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
  render_png "$SRC_SVG_ROUNDED" 192 "${ROOT_DIR}/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"

  # Adaptive icon layers (Android 8.0+). Layer size is 108dp.
  render_png "$SRC_ANDROID_ADAPTIVE_BG_SVG" 108 "${ROOT_DIR}/android/app/src/main/res/mipmap-mdpi/ic_launcher_background.png"
  render_png "$SRC_ANDROID_ADAPTIVE_BG_SVG" 162 "${ROOT_DIR}/android/app/src/main/res/mipmap-hdpi/ic_launcher_background.png"
  render_png "$SRC_ANDROID_ADAPTIVE_BG_SVG" 216 "${ROOT_DIR}/android/app/src/main/res/mipmap-xhdpi/ic_launcher_background.png"
  render_png "$SRC_ANDROID_ADAPTIVE_BG_SVG" 324 "${ROOT_DIR}/android/app/src/main/res/mipmap-xxhdpi/ic_launcher_background.png"
  render_png "$SRC_ANDROID_ADAPTIVE_BG_SVG" 432 "${ROOT_DIR}/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_background.png"

  render_png "$SRC_ANDROID_ADAPTIVE_FG_SVG" 108 "${ROOT_DIR}/android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png"
  render_png "$SRC_ANDROID_ADAPTIVE_FG_SVG" 162 "${ROOT_DIR}/android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png"
  render_png "$SRC_ANDROID_ADAPTIVE_FG_SVG" 216 "${ROOT_DIR}/android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png"
  render_png "$SRC_ANDROID_ADAPTIVE_FG_SVG" 324 "${ROOT_DIR}/android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png"
  render_png "$SRC_ANDROID_ADAPTIVE_FG_SVG" 432 "${ROOT_DIR}/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png"
}

update_ios() {
  render_set_from_contents_json \
    "$SRC_SVG" \
    "${ROOT_DIR}/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" \
    "${ROOT_DIR}/ios/Runner/Assets.xcassets/AppIcon.appiconset"
}

update_macos() {
  render_set_from_contents_json \
    "$SRC_SVG_ROUNDED" \
    "${ROOT_DIR}/macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" \
    "${ROOT_DIR}/macos/Runner/Assets.xcassets/AppIcon.appiconset"
}

update_web() {
  render_png "$SRC_SVG_ROUNDED" 192 "${ROOT_DIR}/web/icons/Icon-192.png"
  render_png "$SRC_SVG_ROUNDED" 512 "${ROOT_DIR}/web/icons/Icon-512.png"
  render_png "$SRC_MASKABLE_SVG" 192 "${ROOT_DIR}/web/icons/Icon-maskable-192.png"
  render_png "$SRC_MASKABLE_SVG" 512 "${ROOT_DIR}/web/icons/Icon-maskable-512.png"
  render_png "$SRC_SVG_ROUNDED" 16 "${ROOT_DIR}/web/favicon.png"
}

update_windows() {
  local out_ico="${ROOT_DIR}/windows/runner/resources/app_icon.ico"
  local tmpdir
  mkdir -p "$TMP_ROOT"
  tmpdir="$(mktemp -d "${TMP_ROOT}/win.XXXXXX")"
  trap 'rm -rf "$tmpdir"' RETURN

  local base_png="${tmpdir}/icon_256.png"
  render_png "$SRC_SVG_ROUNDED" 256 "$base_png"

  if have magick; then
    magick "$base_png" -define icon:auto-resize=256,128,64,48,32,16 "$out_ico"
  else
    if python3 - "$base_png" "$out_ico" <<'PY'
from PIL import Image
import sys

src, dst = sys.argv[1], sys.argv[2]
img = Image.open(src).convert("RGBA")
img.save(dst, format="ICO", sizes=[(256,256),(128,128),(64,64),(48,48),(32,32),(16,16)])
PY
    then
      :
    else
      echo "Skip windows .ico: need ImageMagick (magick) or Python Pillow. Existing file kept: $out_ico" >&2
    fi
  fi

  trap - RETURN
  rm -rf "$tmpdir"
}

update_linux() {
  render_png "$SRC_SVG_ROUNDED" 256 "${ROOT_DIR}/linux/appimage/AppRun.png"
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ ! -f "$SRC_BG_SVG" ]]; then
    echo "Missing SRC_BG_SVG: $SRC_BG_SVG" >&2
    exit 1
  fi
  if [[ ! -f "$SRC_FG_SVG" ]]; then
    echo "Missing SRC_FG_SVG: $SRC_FG_SVG" >&2
    exit 1
  fi

  generate_svgs

  update_android
  update_ios
  update_macos
  update_web
  update_windows
  update_linux

  mkdir -p "$OUT_DIR"
  render_png "$SRC_SVG_ROUNDED" 1024 "${OUT_DIR}/app_icon_rounded_1024.png"

  echo "Icons updated."
}

main "$@"
