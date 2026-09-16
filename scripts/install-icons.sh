#!/bin/bash
# Build the "Ghost Of Omarchy" icon theme: Papirus-Dark with folders recoloured
# to the theme palette. Only the folder family is touched -- application icons
# that happen to use Papirus blue are left alone, and the 16x16 set is symbolic
# (it follows currentColor) so it needs no recolouring.
set -euo pipefail

SRC=/usr/share/icons/Papirus-Dark
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/icons/GhostOfOmarchy"
SIZES=(22x22 24x24 32x32 48x48 64x64 96x96 128x128)
CONTEXTS=(places mimetypes)

if [[ ! -d $SRC ]]; then
  echo "Papirus-Dark not found. Install it first: omarchy pkg add papirus-icon-theme" >&2
  exit 1
fi

# Papirus folder art is flat: a front face, a darker back tab, a paper sheet,
# and a dark emblem glyph. Map each onto the palette from colors.toml.
recolour() {
  sed -e 's/#5294e2/#c2913f/gI' \
      -e 's/#4877b1/#937140/gI' \
      -e 's/#1d344f/#1a1512/gI' \
      -e 's/#e4e4e4/#e9e3d6/gI' "$1"
}

rm -rf "$DEST"
mkdir -p "$DEST"

count=0
for size in "${SIZES[@]}"; do
  for ctx in "${CONTEXTS[@]}"; do
    [[ -d $SRC/$size/$ctx ]] || continue
    mkdir -p "$DEST/$size/$ctx"
    for icon in "$SRC/$size/$ctx"/*.svg; do
      [[ -e $icon ]] || continue
      real=$(readlink -f "$icon")
      grep -qE '#5294e2|#4877b1' "$real" 2>/dev/null || continue
      recolour "$real" > "$DEST/$size/$ctx/$(basename "$icon")"
      count=$((count + 1))
    done
    rmdir "$DEST/$size/$ctx" 2>/dev/null || true
  done
done

{
  echo "[Icon Theme]"
  echo "Name=Ghost Of Omarchy"
  echo "Comment=Papirus-Dark with ginkgo gold folders"
  echo "Inherits=Papirus-Dark,Papirus,Adwaita,hicolor"
  echo "Example=folder"
  echo "FollowsColorScheme=true"
  echo
  dirs=()
  for size in "${SIZES[@]}"; do
    for ctx in "${CONTEXTS[@]}"; do
      [[ -d $DEST/$size/$ctx ]] && dirs+=("$size/$ctx")
    done
  done
  printf 'Directories=%s\n' "$(IFS=,; echo "${dirs[*]}")"
  echo
  for d in "${dirs[@]}"; do
    echo "[$d]"
    echo "Context=${d##*/}"
    echo "Size=${d%%x*}"
    echo "Type=Fixed"
    echo
  done
} > "$DEST/index.theme"

# Context values must be capitalised the way the spec names them.
sed -i -e 's/^Context=places$/Context=Places/' -e 's/^Context=mimetypes$/Context=MimeTypes/' "$DEST/index.theme"

command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q -f -t "$DEST" 2>/dev/null || true

echo "Recoloured $count icons into $DEST"
