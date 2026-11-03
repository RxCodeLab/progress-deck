"""Checks for a built deck (run through scripts/deck.sh, which supplies python-pptx and pypdfium2 via uv).

    inspect_deck.py check <deck.pptx> <text.md>   open the deck, list shapes that run off the slide, write the slide text
    inspect_deck.py raster <deck.pdf> <outdir>    one PNG per page (slide-01.png, ...) at about 100 dpi
"""
import sys
from pathlib import Path


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

    for i, s in enumerate(p.slides, 1):
        lines += [f"<!-- Slide number: {i} -->"]
        for sh in shapes(s.shapes):
            if None not in (sh.left, sh.top, sh.width, sh.height):
                if sh.left < 0 or sh.top < 0 or sh.left + sh.width > W + Emu(9525) or sh.top + sh.height > H + Emu(9525):
                    off.append(f"slide {i}: '{sh.name}' ends at {(sh.left + sh.width) / 914400:.2f} x {(sh.top + sh.height) / 914400:.2f} in "
                               f"(slide {W / 914400:.2f} x {H / 914400:.2f})")
            if sh.has_text_frame and sh.text_frame.text.strip():
                lines.append(sh.text_frame.text.strip())
            elif sh.shape_type == 13:   # picture
                lines.append(f"[image: {sh._element.xpath('.//p:cNvPr/@descr')[0] if sh._element.xpath('.//p:cNvPr/@descr') else sh.name}]")
            elif sh.has_table:
                for r in sh.table.rows:
                    lines.append("| " + " | ".join(c.text.strip() for c in r.cells) + " |")
        lines.append("")
    Path(md).write_text("\n".join(lines), encoding="utf-8")
    print(f"opened: {len(p.slides)} slides; text written to {md}")
    print("off-slide shapes: none" if not off else "off-slide shapes:\n  " + "\n  ".join(off))
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
