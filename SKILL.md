---
name: progress-deck
description: Build research progress decks (.pptx) from R output - package plots, tables rendered in R and black-and-grey design diagrams placed on slides with pptxgenjs, with almost no written text. Use this whenever the user asks for a progress deck, progress report slides, slides for an advisor or lab meeting about an analysis, or wants R results (Kaplan-Meier, propensity score, covariate balance, forest plots, Table 1) put into PowerPoint, even if they only say "make the slides", "덱 만들어줘" or "진행 보고 ppt". Also use it to set the deck toolchain up on a new server.
license: MIT
---

# Progress decks from R output

A progress deck here is a set of slides that shows an analysis to an advisor or collaborators through its R output: the plots and tables the R packages produce, placed on slides with a title line and, where needed, a source line. The output carries the evidence; written sentences on the slides invite debate about wording instead of the results, so the slides hold almost none.

The skill has five parts:
- `lib/deck_lib.js` places R images on 16:9 slides (pptxgenjs);
- `templates/` has R code for slide tables, design diagrams and cumulative incidence curves, plus an example build script;
- `references/annals_figures.md` holds the Annals of Internal Medicine figure rules and examples from its papers;
- `scripts/setup.sh` installs the toolchain per server without sudo;
- `scripts/deck.sh` builds a deck and checks it, rendering every slide to PNG.

## Setup, once per server

```bash
bash <skill-dir>/scripts/setup.sh
```

It installs pptxgenjs and sharp, unpacks LibreOffice (previews only) and warms uv's cache of python-pptx and pypdfium2, all under `~/.local/share/progress-deck` (override with `PROGRESS_DECK_HOME`). It reports anything missing (Node, uv, R packages, system libraries) instead of failing silently. Rerunning it is safe.

## Rules for the slides

These come from repeated feedback on real decks. Each has a reason; keep the reason in mind when a case is not covered.

1. **R output, not sentences.** Fill slides with the R results themselves. At most a short title, and a subtitle only when it carries a needed fact (a window, a population size). Numbers computed elsewhere (SQL or Python counts) are turned into a table or plot in R before they go on a slide.
2. **Package graphs and tables as they come.** Propensity-score and balance plots from the package that fitted the model (for example CohortMethod `plotKaplanMeier`, `plotPs`, `plotCovariateBalanceScatterPlot`), Table 1 from `createCmTable1`, forest plots from an R package (`meta::forest`). Never redraw a data graph as PowerPoint shapes or a native chart; a redrawn graph can drift from the analysis, a package graph cannot. The exception is the survival curve: `plotKaplanMeier` only draws falling survival, so time-to-event results are drawn as cumulative incidence in R from the same population and weights (rule 13).
3. **A table when a chart adds nothing.** A list of numbers per item (group sizes, counts per design, estimates per outcome) goes in a table rendered in R (`templates/table_grob.R`), not a dot or bar chart. Charts are for what a table cannot show at a glance, such as how N falls step by step.
4. **Design diagrams in R, black and grey.** Inclusion and exclusion criteria as a design diagram (time on the x-axis around day 0, one box per criterion over its assessment window; Schneeweiss S et al., Ann Intern Med 2019;170:398-406) from `templates/design_diagram.R`, PNG for slides and PDF for a paper. Flow diagrams are drawn in R too.
5. **Plain names, not internal codes.** Name each analysis by what it studies ("Drug A start vs no start, disease X"), never by working codes such as B1, S3, v4 or design numbers. The audience has never seen the codes.
6. **One deck per analysis, in a paper's order** (background, methods, results), so each analysis can move on its own; a combined deck is at most an overview. Each progress deck is a new file in a new dated folder (for example `progress_2026-11/`); an earlier deck is never edited into the next one.
7. **For an advisor, stop at the results.** No limitations, discussion or next steps unless asked, no interpretive commentary, no speaker-note chatter, and nothing from the working process: no tool or AI names, review numbers, file paths, prompts or people's names.
8. **No filler boxes.** Leave out a takeaway box at the bottom unless it carries needed content that is nowhere else. Generated decks tend to squeeze filler into such boxes; what is needed belongs in the title or the figure.
9. **Full citations.** Source lines give first author et al., journal abbreviation, year;volume:pages, never author-year alone. Verify every citation; never invent a volume, page or journal.
10. **Real counts.** Show counts as they are: no "<5", no masking, no complementary suppression, no rounding sizes to 5, unless the user says a data-use agreement requires it. Analysis rules are different (for example no hazard ratio with fewer than 10 events); state them and still show the counts.
11. **Plain design.** White slides, including the title slide, black text in one font (Arial), a grey subtitle and source line, and nothing else: no dark title slides, colour accents, small-caps section tags, boxes, pills or decorative shapes. A styled template looks generated and pulls attention away from the R output. The rule is about the slides, not the graphs: colours that R or a package draws by default stay as they are, so groups and arms can be told apart, and nothing is turned grey on purpose.
12. **Any text gets a humanizer pass.** Titles, labels and captions go through the `humanizer` skill when it is installed, and the deck's language follows the user's request.
13. **Figures follow Annals of Internal Medicine.** Deck figures often end up in the paper, so they are drawn to that journal's written rules from the start (`references/annals_figures.md` has the rules, quotes and examples from recent Annals papers; follow another journal's rules when the user names it):
    - time-to-event results go in two R outputs from `templates/cum_incidence.R`. The first is a rising cumulative incidence curve in Okabe-Ito blue and vermilion on a narrow y-axis from 0, with the numbers at risk by group and time below the x-axis. The second is a table of absolute differences with 95% CIs at fixed times;
    - no pie charts, no 3-D graphics, no bars without a measure of variability;
    - ratios go on a log axis with a line at 1, differences on a linear axis with a line at 0;
    - every abbreviation and symbol is explained under the figure;
    - the flow diagram comes first, following CONSORT for a trial, TARGET for a trial emulation and STROBE or RECORD for other observational studies.

## Workflow

1. **Export from R.** One PNG per figure or table, white background, written with `ragg::agg_png` (or `ggsave(..., device = ragg::agg_png)`) at about 220 dpi into one or more image folders. Use unique file names across folders; the library keys images by file name. Draw each figure at the size it should have on the slide. The figure area under a title is about 12.3 x 5.3 in, or half that width for two figures side by side. The library reads the PNG's resolution and never enlarges a figure past its drawn size, so text keeps the point size R drew it with. Shrinking to fit is allowed.
   - For tables: `source("<skill-dir>/templates/table_grob.R"); table_png(df, "img/name.png", notes = ...)`.
   - For a design diagram: `source("<skill-dir>/templates/design_diagram.R"); design_diagram(rows, entry, file = "img/design")`.
   - For a time-to-event outcome: `source("<skill-dir>/templates/cum_incidence.R"); cum_incidence_png(time, event, group, "img/ci_x.png", weights = w, times = 0:5)` and `table_png(cum_incidence_diff(time, event, group, times = 1:5, weights = w), "img/ci_x_diff.png")`. From a CohortMethod population, `time` is `survivalTime / 365.25`, `event` is `outcomeCount > 0` and `group` is `treatment` (1 first). With variable-ratio matching, the weight is 1 for the treated and n treated / n comparator within the stratum for each comparator, as in `plotKaplanMeier`. With IPTW or overlap weights, use those weights.
   - For a long package table that will not fit as one PNG, such as `createCmTable1` with 80 rows, save it with `write.csv` and place it with `csvTable`.
2. **Write the build script.** Copy `templates/build_example.js` next to the image folders and edit it. The library API is below.
3. **Build:** `<skill-dir>/scripts/deck.sh build build_deck.js`.
4. **Check:** `<skill-dir>/scripts/deck.sh check deck.pptx [outdir]`. This opens the deck, lists any shape that runs off the slide, writes the slide text to a Markdown file, runs Anthropic's pptx validator if that skill is installed, and renders every slide to `slide-NN.png`. Look at every rendered slide. Fix overlaps, cut-off tables and figures that came out too small, then rebuild. Proofread the text file for wording and numbers.
5. **Hand over the .pptx file.**

## Library: `lib/deck_lib.js`

`const makeDeck = require('deck_lib'); const D = makeDeck('out.pptx', { title, author });`

| Call | What it does |
|---|---|
| `await D.loadFigs([dir, ...])` | Loads every PNG in the folders, trimmed of white margins, keyed by file name |
| `D.titleSlide(title, sub, foot)` | Plain title slide, centred text |
| `D.sectionSlide(title)` | Plain divider slide |
| `D.figSlide({ title, sub, figs: [a.png, b.png], labels, src, maxScale })` | One to three figures side by side under the title, each fitted into an equal column, never above `maxScale` times its drawn size (default 1); `labels` are optional few-word headings over each figure; `src` is a full citation string or a list of them |
| `D.newSlide()` / `D.title(s, t, sub)` / `D.fig(s, name, x, y, w, h)` / `D.src(s, text)` / `D.cap(s, text, x, y, w)` | Building blocks for a custom layout; `fig` fits the image in the box and returns its placed size |
| `D.csvTable(s, rows, { headRows, columns, fontSize, rowH })` | Long package table from CSV rows (`makeDeck.csvRows(file)`), split into up to three columns |
| `await D.write()` | Writes the file |

Coordinates are inches on a 13.333 x 7.5 slide. Colours are hex strings without `#` (`D.C.text`, `D.C.grey`, `D.C.line`). `makeDeck(out, { slideNumbers: false })` drops the slide numbers; `font` changes the one font. `makeDeck.csv(file)` reads a CSV into objects, for numbers that go into a title or subtitle; read them from the analysis output, never type them in by hand.

## Pitfalls

- **Rendering is only a preview.** LibreOffice draws Arial with the metric-compatible Liberation Sans, so line breaks match closely but not exactly. Leave some room at the bottom of tall tables.
- **Tall `csvTable` tables.** At the default 0.13-inch row height about 40 rows fit per column, fewer when long labels wrap. Check the rendered slide, and pass `columns: 3` or a smaller `fontSize` if a column runs into the source line.
- **Changed figures.** A figure drawn again in R needs a rebuild of the deck; the deck embeds the PNG, not a link to it.
- **pptxgenjs options.** Never pass a colour with `#` or an 8-digit hex, and never share one options object between two `add*` calls (pptxgenjs changes it in place).
