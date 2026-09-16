#!/bin/bash
# Render docs/palette.png -- the swatch sheet the README shows -- straight from
# colors.toml, so the picture cannot drift from the palette it documents.
# Run from anywhere: scripts/render-palette.sh
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC="$ROOT/colors.toml"
OUT="$ROOT/docs/palette.png"
FONT=$(fc-match -f "%{file}" "JetBrainsMono Nerd Font Mono" 2>/dev/null || echo "")
FONTB=$(fc-match -f "%{file}" "JetBrainsMono Nerd Font:weight=bold" 2>/dev/null || echo "$FONT")
[[ -n $FONT ]] || { echo "No usable font found." >&2; exit 1; }

# key -> "#RRGGBB", read out of colors.toml
val() { sed -nE "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"([^\"]+)\".*/\1/p" "$SRC" | head -1; }

BG=$(val darker_background); FG=$(val foreground)
LIGHT=$(val light_foreground); MUTED=$(val muted); LINE=$(val lighter_background)

W=1280; H=624; PAD=88; GAP=16
CW=208; CH=140; CY=76
AW=124; AH=68; AY1=390; AY2=496

CORE_KEYS=(background foreground accent selection muted)
CORE_DESC=("sumi ink" "Yotei snow" "ginkgo gold" "damp earth" "weathered rope")
AN_NAMES=(black red green yellow blue magenta cyan white)
N_KEYS=(background red green yellow blue magenta cyan light_foreground)
B_KEYS=(lighter_background bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan bright_foreground)

args=( -size ${W}x${H} "xc:$BG" )
tile() { args+=( -fill "$5" -stroke "$LINE" -strokewidth 1 -draw "roundrectangle $1,$2 $(($1+$3)),$(($2+$4)) 8,8" -stroke none ); }

x=$PAD
for i in "${!CORE_KEYS[@]}"; do
  hex=$(val "${CORE_KEYS[$i]}")
  tile $x $CY $CW $CH "$hex"
  args+=( -font "$FONTB" -pointsize 17 -fill "$FG"    -annotate +$x+$((CY+CH+34)) "${CORE_KEYS[$i]}" )
  args+=( -font "$FONT"  -pointsize 15 -fill "$LIGHT" -annotate +$x+$((CY+CH+58)) "$hex" )
  args+=( -font "$FONT"  -pointsize 14 -fill "$MUTED" -annotate +$x+$((CY+CH+80)) "${CORE_DESC[$i]}" )
  x=$((x+CW+GAP))
done

args+=( -fill "$LINE" -draw "rectangle $PAD,334 $((W-PAD)),335" )

x=$PAD
for i in "${!AN_NAMES[@]}"; do
  n=$(val "${N_KEYS[$i]}"); b=$(val "${B_KEYS[$i]}")
  args+=( -font "$FONT" -pointsize 13 -fill "$MUTED" -annotate +$x+$((AY1-16)) "${AN_NAMES[$i]}" )
  tile $x $AY1 $AW $AH "$n"
  args+=( -font "$FONT" -pointsize 13 -fill "$MUTED" -annotate +$x+$((AY1+AH+22)) "$n" )
  tile $x $AY2 $AW $AH "$b"
  args+=( -font "$FONT" -pointsize 13 -fill "$MUTED" -annotate +$x+$((AY2+AH+22)) "$b" )
  x=$((x+AW+GAP))
done

magick "${args[@]}" -depth 8 "$OUT"
echo "wrote $OUT"
