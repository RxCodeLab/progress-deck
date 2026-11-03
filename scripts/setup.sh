#!/usr/bin/env bash
# One-time setup per server, no sudo. Everything goes under $PROGRESS_DECK_HOME (default ~/.local/share/progress-deck):
#   node/node_modules   pptxgenjs and sharp, from npm (sharp needs Node 20.9 or later)
#   libreoffice/        LibreOffice unpacked from the official .deb tarball (x86-64 or aarch64), used only for previews
#   lo-profile/         LibreOffice's user profile for headless runs
# Python (3.12 with python-pptx and pypdfium2) is fetched by uv when the check script runs; this script warms the cache.
# R packages are checked, not installed. Exits non-zero if anything required is missing; rerunning is safe.
#   bash scripts/setup.sh
#   SKIP_LIBREOFFICE=1 bash scripts/setup.sh
#   LO_TARBALL=/path/LibreOffice_..._deb.tar.gz bash scripts/setup.sh   # use a tarball already downloaded
set -euo pipefail
DECK_HOME=$(realpath -m "${PROGRESS_DECK_HOME:-$HOME/.local/share/progress-deck}")
LO_VERSION=${LO_VERSION:-25.8.7}
LO_FULL=${LO_FULL:-25.8.7.3}
mkdir -p "$DECK_HOME"
failed=0
ok() { printf '  ok    %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; failed=1; }
warn() { printf '  WARN  %s\n' "$*"; }

echo "progress-deck setup in $DECK_HOME"

# --- Node packages ---------------------------------------------------------------------------------------------
if command -v node >/dev/null && command -v npm >/dev/null; then
  if ! node -e 'const [a, b] = process.versions.node.split(".").map(Number); process.exit(a > 20 || (a === 20 && b >= 9) ? 0 : 1)'; then
    fail "node $(node --version) is too old: sharp needs Node 20.9 or later (for example: nvm install --lts)"
  else
    mkdir -p "$DECK_HOME/node"
    [ -f "$DECK_HOME/node/package.json" ] || \
      printf '{\n  "name": "progress-deck-runtime",\n  "private": true,\n  "dependencies": { "pptxgenjs": "^4.0.1", "sharp": "^0.35.5" }\n}\n' > "$DECK_HOME/node/package.json"
    if (cd "$DECK_HOME/node" && npm install --no-audit --no-fund --silent) && \
       NODE_PATH="$DECK_HOME/node/node_modules" node -e "require('pptxgenjs'); require('sharp')"; then
      ok "node $(node --version): pptxgenjs, sharp"
    else
      fail "npm install of pptxgenjs and sharp failed (see the npm output above)"
    fi
  fi
else
  fail "node and npm not found: install Node 20.9 or later (for example with nvm), then rerun"
fi

# --- uv and the Python packages it fetches ---------------------------------------------------------------------
if command -v uv >/dev/null; then
  if uv run -q --no-project --python 3.12 --with python-pptx --with pypdfium2 python -c "import pptx, pypdfium2"; then
    ok "uv: python 3.12, python-pptx, pypdfium2"
  else
    fail "uv could not provide python 3.12 with python-pptx and pypdfium2"
  fi
else
  fail "uv not found: see https://docs.astral.sh/uv/getting-started/installation/ (a user install needs no sudo), then rerun"
fi

# --- LibreOffice, unpacked without sudo (previews only) ---------------------------------------------------------
case "$(uname -m)" in
  x86_64) LO_ARCH=x86_64; LO_TAG=x86-64 ;;
  aarch64|arm64) LO_ARCH=aarch64; LO_TAG=aarch64 ;;
  *) LO_ARCH=; LO_TAG= ;;
esac
if [ "${SKIP_LIBREOFFICE:-0}" = 1 ]; then
  warn "LibreOffice skipped: decks still build and pass the open check, but no slide images are rendered"
elif ls "$DECK_HOME"/libreoffice/opt/libreoffice*/program/soffice >/dev/null 2>&1; then
  ok "LibreOffice already unpacked"
elif [ -z "$LO_ARCH" ] && [ -z "${LO_TARBALL:-}" ]; then
  warn "no LibreOffice .deb build for $(uname -m): slides will not be rendered (set LO_TARBALL to a tarball to use one)"
else
  tmp=$(mktemp -d)
  tarball=${LO_TARBALL:+$(realpath "$LO_TARBALL")}
  if [ -z "$tarball" ]; then
    tarball="$tmp/lo.tar.gz"
    for url in "https://download.documentfoundation.org/libreoffice/stable/$LO_VERSION/deb/$LO_ARCH/LibreOffice_${LO_VERSION}_Linux_${LO_TAG}_deb.tar.gz" \
               "https://downloadarchive.documentfoundation.org/libreoffice/old/$LO_FULL/deb/$LO_ARCH/LibreOffice_${LO_FULL}_Linux_${LO_TAG}_deb.tar.gz"; do
      echo "  downloading $url"
      if curl -fL --retry 2 -o "$tarball" "$url"; then break; fi
      rm -f "$tarball"
    done
  fi
  if [ -f "$tarball" ] && tar -xzf "$tarball" -C "$tmp"; then
    mkdir -p "$DECK_HOME/libreoffice"
    for deb in "$tmp"/LibreOffice_*/DEBS/*.deb; do
      if command -v dpkg-deb >/dev/null; then dpkg-deb -x "$deb" "$DECK_HOME/libreoffice"
      else (cd "$tmp" && ar x "$deb" && tar -xf data.tar.* -C "$DECK_HOME/libreoffice" && rm -f data.tar.* control.tar.* debian-binary); fi
    done
    ok "LibreOffice unpacked"
  else
    warn "LibreOffice download or unpacking failed: slides will not be rendered"
  fi
  rm -rf "$tmp"
fi
SOFFICE=$(ls "$DECK_HOME"/libreoffice/opt/libreoffice*/program/soffice 2>/dev/null | head -1 || true)
if [ -n "$SOFFICE" ]; then
  missing=$(ldd "$(dirname "$SOFFICE")/soffice.bin" 2>/dev/null | grep "not found" || true)
  if [ -n "$missing" ]; then warn "LibreOffice needs system libraries that are missing: $missing"; fi
fi

# --- R packages used by the templates ---------------------------------------------------------------------------
if command -v Rscript >/dev/null; then
  if Rscript -e 'm <- Filter(function(p) !requireNamespace(p, quietly = TRUE), c("ggplot2", "ragg", "gridExtra", "gtable"));
                 if (length(m)) { cat("  FAIL  missing R packages:", m, "\n"); quit(status = 1) }
                 cat("  ok    R packages: ggplot2, ragg, gridExtra, gtable\n")'; then :; else failed=1; fi
else
  fail "Rscript not found: the templates need R with ggplot2, ragg, gridExtra and gtable"
fi

if [ "$failed" = 1 ]; then echo "setup incomplete: fix the FAIL lines and rerun"; exit 1; fi
echo "done"
