#!/usr/bin/env bash
# deck.sh build <build_script.js> [args]   run a pptxgenjs build script with the runtime packages and lib/ on NODE_PATH
# deck.sh check <deck.pptx> [outdir]       open check, off-slide shapes, slide text, and one PNG per slide to look at
# Setup first: bash scripts/setup.sh
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DECK_HOME=$(realpath -m "${PROGRESS_DECK_HOME:-$HOME/.local/share/progress-deck}")
PY=(uv run -q --no-project --python 3.12 --with python-pptx --with pypdfium2 python "$HERE/scripts/inspect_deck.py")

cmd=${1:-}; shift || true
case "$cmd" in
  build)
    [ -d "$DECK_HOME/node/node_modules" ] || { echo "run scripts/setup.sh first"; exit 1; }
    NODE_PATH="$DECK_HOME/node/node_modules:$HERE/lib${NODE_PATH:+:$NODE_PATH}" node "$@"
    ;;
  check)
    deck=$(realpath "$1"); name=$(basename "$deck" .pptx)
    out=$(realpath -m "${2:-${TMPDIR:-/tmp}/progress-deck-check/$name}"); mkdir -p "$out"
    "${PY[@]}" check "$deck" "$out/$name.md"
    # Anthropic's pptx skill validator, if that skill is installed here (it is not part of this repository)
    v=$(ls "$HOME"/.claude/skills/synced/*/pptx/scripts/office/validate.py "$HOME"/.claude/skills/pptx/scripts/office/validate.py 2>/dev/null | head -1 || true)
    if [ -n "$v" ]; then uv run -q --no-project --python 3.12 --with lxml --with defusedxml python "$v" "$deck" | tail -n 1; fi
    soffice=$(ls "$DECK_HOME"/libreoffice/opt/libreoffice*/program/soffice 2>/dev/null | head -1 || true)
    if [ -n "$soffice" ]; then
      timeout 600 "$soffice" -env:UserInstallation="file://$DECK_HOME/lo-profile" --headless --convert-to pdf --outdir "$out" "$deck" >/dev/null 2>&1
      rm -f "$out"/slide-*.png
      "${PY[@]}" raster "$out/$name.pdf" "$out"
    else
      echo "no LibreOffice under $DECK_HOME: slides not rendered (run scripts/setup.sh)"
    fi
    echo "check output: $out"
    ;;
  *) sed -n '2,4p' "$0"; exit 1 ;;
esac
