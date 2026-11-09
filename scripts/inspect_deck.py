"""Checks for a built deck (run through scripts/deck.sh, which supplies python-pptx and pypdfium2 via uv).

    inspect_deck.py check <deck.pptx> <text.md>   open the deck, list shapes that run off the slide, write the slide text
    inspect_deck.py raster <deck.pdf> <outdir>    one PNG per page (slide-01.png, ...) at about 100 dpi
"""
import os
import re
import sys
from pathlib import Path

# Mistakes caught in earlier decks, checked in the slide text (text inside images is not seen here):
# masked counts, AI tool names, file paths, author-year-only citations, and the project's own working codes
# (DECK_CODES, comma-separated words such as "B1,S3,v4", which never belong on a slide).
LINT = [
    (re.compile(r"(?<![\w.])<\s?(5|10|11)\b"), "masked count"),
    (re.compile(r"\b(Codex|Claude|ChatGPT|GPT-?\d|Copilot|Gemini)\b"), "tool name"),
    (re.compile(r"(/home/|/tmp/|\w+\.(R|py|js|csv|tsv|rds|sql)\b)"), "file path"),
]
YEAR = re.compile(r"\b(19|20)\d{2}\b")
FULL = re.compile(r"(19|20)\d{2};\s?\d|doi|PMID|https?://|ahead of print", re.I)


def lint(slides):
    codes = [c.strip() for c in os.environ.get("DECK_CODES", "").split(",") if c.strip()]
    pats = LINT + [(re.compile(r"\b" + re.escape(c) + r"\b"), f"working code {c}") for c in codes]
    found = []
    for i, (texts, sources) in enumerate(slides, 1):
        for t in texts:
            for rx, what in pats:
                m = rx.search(t)
                if m:
                    found.append(f"slide {i}: {what}: '{m.group(0)}' in '{t[:70]}'")
        for t in sources:   # source lines: every cited work needs its journal, volume and pages (or a DOI, PMID or URL)
            for part in t.split("; "):
                if YEAR.search(part) and not FULL.search(part):
                    found.append(f"slide {i}: citation without volume and pages, DOI, PMID or URL (check it): '{part[:70]}'")
    return found


def check(deck, md):
    from pptx import Presentation
    from pptx.util import Emu
    p = Presentation(deck)
    W, H = p.slide_width, p.slide_height
    off, lines = [], [f"# {Path(deck).stem}: slide text", ""]
    def shapes(coll):   # grouped shapes too, in reading order
        for sh in coll:
            yield sh
            if sh.shape_type == 6:   # group
                yield from shapes(sh.shapes)

    per_slide = []
    for i, s in enumerate(p.slides, 1):
        lines += [f"<!-- Slide number: {i} -->"]
        texts, sources = [], []
        per_slide.append((texts, sources))
        for sh in shapes(s.shapes):
            if None not in (sh.left, sh.top, sh.width, sh.height):
                if sh.left < 0 or sh.top < 0 or sh.left + sh.width > W + Emu(9525) or sh.top + sh.height > H + Emu(9525):
                    off.append(f"slide {i}: '{sh.name}' ends at {(sh.left + sh.width) / 914400:.2f} x {(sh.top + sh.height) / 914400:.2f} in "
                               f"(slide {W / 914400:.2f} x {H / 914400:.2f})")
            if sh.has_text_frame and sh.text_frame.text.strip():
                lines.append(sh.text_frame.text.strip())
                texts.append(sh.text_frame.text.strip())
                runs = [r for para in sh.text_frame.paragraphs for r in para.runs]
                small = bool(runs) and runs[0].font.size is not None and runs[0].font.size.pt <= 10
                if sh.top is not None and sh.top > H * 0.85 and small:   # the source line: small text at the bottom
                    sources.append(sh.text_frame.text.strip())
            elif sh.shape_type == 13:   # picture
                lines.append(f"[image: {sh._element.xpath('.//p:cNvPr/@descr')[0] if sh._element.xpath('.//p:cNvPr/@descr') else sh.name}]")
            elif sh.has_table:
                for r in sh.table.rows:
                    lines.append("| " + " | ".join(c.text.strip() for c in r.cells) + " |")
        lines.append("")
    Path(md).write_text("\n".join(lines), encoding="utf-8")
    print(f"opened: {len(p.slides)} slides; text written to {md}")
    print("off-slide shapes: none" if not off else "off-slide shapes:\n  " + "\n  ".join(off))
    found = lint(per_slide)
    print("lint (slide text only): none" if not found else "lint (slide text only):\n  " + "\n  ".join(found))
    return 1 if off else 0


def raster(pdf, outdir, dpi=100):
    import pypdfium2 as pdfium
    doc = pdfium.PdfDocument(pdf)
    for i in range(len(doc)):
        doc[i].render(scale=dpi / 72).to_pil().save(Path(outdir) / f"slide-{i + 1:02d}.png")
    print(f"rendered {len(doc)} slides to {outdir}/slide-NN.png")


if __name__ == "__main__":
    if len(sys.argv) == 4 and sys.argv[1] == "check":
        sys.exit(check(sys.argv[2], sys.argv[3]))
    elif len(sys.argv) == 4 and sys.argv[1] == "raster":
        raster(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)
