# progress-deck

A Claude Code skill for research progress decks built from R output: package plots, tables rendered in R and design diagrams, placed on 16:9 slides with [pptxgenjs](https://github.com/gitbrent/PptxGenJS), with almost no written text. `SKILL.md` holds the rules and the workflow that Claude follows. Figures follow the written rules of Annals of Internal Medicine (cumulative incidence curves with numbers at risk, risk-difference tables, flow diagrams by reporting guideline); `references/annals_figures.md` has the rules with quotes and sources, and examples from recent Annals papers.

## Install on a server

```bash
git clone https://github.com/rxcodelab/progress-deck.git ~/.claude/skills/progress-deck
bash ~/.claude/skills/progress-deck/scripts/setup.sh
```

The setup needs no sudo. It installs into `~/.local/share/progress-deck`, and you can change that location with `PROGRESS_DECK_HOME`. It needs:

- **Node 20.9 or later**, which sharp requires. It installs pptxgenjs and sharp from npm.
- **[uv](https://docs.astral.sh/uv/).** uv fetches Python 3.12, python-pptx and pypdfium2 for the checks.
- **R** with ggplot2, ragg, gridExtra, gtable and survival, for the templates.

It also downloads and unpacks LibreOffice, which is used only to render previews. Set `SKIP_LIBREOFFICE=1` to skip it, or `LO_TARBALL=<file>` to use a tarball you already have.

Claude Code picks the skill up from `~/.claude/skills/` in new sessions. To update it, run `git -C ~/.claude/skills/progress-deck pull`.

## Use

Ask Claude for a progress deck, or run the tools yourself:

```bash
cd my-project/deck_2026-11                                # img/ holds the PNGs written by R
Rscript ~/.claude/skills/progress-deck/templates/design_diagram.R   # demo PNGs into img/
Rscript ~/.claude/skills/progress-deck/templates/table_grob.R
Rscript ~/.claude/skills/progress-deck/templates/cum_incidence.R
~/.claude/skills/progress-deck/scripts/deck.sh build ~/.claude/skills/progress-deck/templates/build_example.js
~/.claude/skills/progress-deck/scripts/deck.sh check example_progress.pptx   # slide PNGs and text in /tmp/progress-deck-check/
```

## Licence

MIT (see `LICENSE`). Third-party software is not included in this repository. `setup.sh` downloads it from its official sources, and each package keeps its own licence:

| Software | Licence |
|---|---|
| pptxgenjs | MIT |
| sharp | Apache-2.0 (the libvips binaries it downloads are LGPL-3.0) |
| LibreOffice | MPL-2.0 |
| python-pptx | MIT |
| pypdfium2 | Apache-2.0 or BSD-3-Clause (PDFium: BSD-3-Clause) |
| ggplot2, ragg, gtable | MIT |
| gridExtra | GPL-2 or later |
| survival | LGPL-2 or later |

`deck.sh check` also runs the validator from Anthropic's `pptx` skill when that skill is installed on the machine. That validator is proprietary and is not part of this repository.
