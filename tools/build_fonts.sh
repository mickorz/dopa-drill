#!/usr/bin/env bash
# Rebuild the subset WOFF2 fonts used by the game from the Google Fonts (OFL) sources.
# Requires: curl, python3 (with venv + pip). Usage: bash tools/build_fonts.sh
set -euo pipefail
GAME="$(cd "$(dirname "$0")/../app" && pwd)"
WORK="$(mktemp -d)"
BASE=https://raw.githubusercontent.com/google/fonts/main/ofl
curl -sSfo "$WORK/kuaile.ttf" "$BASE/zcoolkuaile/ZCOOLKuaiLe-Regular.ttf"
curl -sSfo "$WORK/huangyou.ttf" "$BASE/zcoolqingkehuangyou/ZCOOLQingKeHuangYou-Regular.ttf"
curl -sSfo "$GAME/fonts/OFL-ZCOOLKuaiLe.txt" "$BASE/zcoolkuaile/OFL.txt"
curl -sSfo "$GAME/fonts/OFL-ZCOOLQingKeHuangYou.txt" "$BASE/zcoolqingkehuangyou/OFL.txt"
python3 - "$GAME" "$WORK/chars.txt" <<'PY'
import sys, pathlib
game = pathlib.Path(sys.argv[1])
chars = {chr(c) for c in range(0x20, 0x7f)}
for f in [*game.glob('*.html'), *game.glob('*.css'), *game.glob('js/*.js')]:
    chars |= set(f.read_text(encoding='utf-8'))
chars |= set('０１２３４５６７８９＋−×÷＝％．，。、！？：；（）—…·☆★♪')
pathlib.Path(sys.argv[2]).write_text(''.join(sorted(c for c in chars if ord(c) >= 0x20)), encoding='utf-8')
PY
python3 -m venv "$WORK/.venv"
"$WORK/.venv/bin/pip" -q install fonttools brotli
for pair in "kuaile zcool-kuaile" "huangyou zcool-qingke-huangyou"; do
  set -- $pair
  "$WORK/.venv/bin/pyftsubset" "$WORK/$1.ttf" --text-file="$WORK/chars.txt" --flavor=woff2 --layout-features='*' --output-file="$GAME/fonts/$2.woff2"
done
rm -rf "$WORK"
echo "fonts rebuilt in $GAME/fonts"
