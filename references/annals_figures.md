# Figures to Annals of Internal Medicine rules

Read on 2026-11-05 from the Annals author pages (author instructions dated 2026-09-16), the Annals statistical guidance, the reporting guidelines it names and three recent Annals papers. Annals has no drawing template: it sets no fonts, sizes, colours, dpi, panel layout or panel letters, and it copyedits accepted figures to its own style. What it does write down is below. Most of it is worded as a recommendation ("should", "rules of thumb"), and the label on each point says whether it comes from Annals, from a reporting guideline or only from published practice.

## What Annals writes down

**Graphs** (statistical guidance, Presentation, Figures), quoted in full:

> When developing informative graphics, follow these simple rules of thumb:
> Avoid pie charts and 3-dimensional graphics.
> Avoid simple bar plots that do not present measures of variability.
> For meta-analysis forest plots, provide the raw data (numerators and denominators) in the margins.
> For survival plots, provide the numbers of people at risk by group and time below the horizontal axis.

**Time-to-event results** (statistical guidance, Hazard Ratios and Standardized Cumulative Incidence): "we recommend that authors present cumulative incidence curves (inverted Kaplan-Meier plots) along with tabular summaries of absolute differences in cumulative incidence, with 95% confidence bounds, at meaningful times". With covariate adjustment, "covariate-standardized (weighted) cumulative incidence curves with differences in adjusted cumulative incidence at meaningful times". So the curve rises from 0, and a table of risk differences at fixed times goes with it.

**Numbers shown in figures and legends** (statistical guidance, Presentation and Measures of Effect):
- Confidence intervals rather than standard errors.
- Between-group differences with 95% CIs, not within-group changes; absolute numbers where feasible.
- Percentages with one decimal when the sample is 200 or more, none below 200.
- Mean (SD), not mean ± SD.
- P values: three decimals from 0.001 to 0.20, two above 0.20, and P<0.001 below that. "Trend" only for a real trend test.
- Missing data: "Consider adding" a row beneath a figure (or a table column) showing how much data are missing.

**Legends** (Preparing Manuscripts, section 8, Figures):
- Each legend starts with a short title, written in phrases.
- It explains "all abbreviations and symbols" in the figure, even ones already defined in the text.
- Figures are numbered with Arabic numerals in the order the text first mentions them.

**Files and limits:**
- Figures go in as TIFF, GIF, JPG, PDF, PostScript or EPS (submission system instructions). PNG and SVG are not on the list.
- Every uploaded figure needs a short description in the submission system (required).
- Original Research: "No more than 4-6 tables or figures (combined)". The rest goes in the supplement, which has its own contents page and its own numbering (Supplement Figure 1). Editors may move items between the article and the supplement.
- Annals makes the visual abstract itself, so authors do not supply one (editorial: Jackson J et al., Ann Intern Med 2023;176:1554-1556).

## Flow and design diagrams (from the reporting guidelines)

Annals tells authors to follow the relevant reporting guideline and names CONSORT and STROBE. It does not name TARGET or RECORD.

| Design | Guideline | Figure |
|---|---|---|
| Randomised trial | CONSORT 2025, item 22 | Participant flow diagram: randomised, received the intervention, analysed, losses and exclusions with reasons, by group |
| Target trial emulation | TARGET (Cashin AG et al., JAMA 2025;334:1084-1093), item 8 | Numbers assessed, eligible and assigned to each strategy: "A flow diagram is strongly recommended". Templates at target-guideline.org |
| Other observational study | STROBE, item 13(c) | "Consider use of a flow diagram", with no set format |
| Routinely collected data (EHR, claims) | RECORD, items 13.1 and 6.3 | Selection in text and/or a flow diagram, including data-quality filters and any linkage |
| Database study design | Schneeweiss S et al., Ann Intern Med 2019;170:398-406 | Design diagram: time around cohort entry (day 0), one box per window (washout, exclusions, covariates, exposure, follow-up) |

## Not specified anywhere

- y-axis range;
- whether the y-axis starts at 0;
- shaded confidence bands;
- log scale for ratios;
- cutting the curve when few people remain at risk;
- panel letters;
- interaction P values or "favours" labels in subgroup plots;
- dots or box plots for continuous data;
- a figure resolution;
- figure widths.

The statistical guidance lists Pocock SJ et al., Lancet 2002;359:1686-1689 (survival plots in trials) as further reading, without adopting its suggestions as rules.

## What recent Annals papers do (practice, not rules)

| Paper | Figures |
|---|---|
| Ruiz-Canela M et al., Ann Intern Med 2025;178:1378-1390 (randomised trial) | Figure 1 is the CONSORT flow diagram. Figure 2 is a rising cumulative incidence curve with a y-axis from 0 to about 0.18 over 7 years, shaded 95% bands and a two-row number-at-risk table at yearly times. The adjusted HR with its CI is inside the plot, and the group names sit at the curve ends. Figure 3 is a 2 x 2 grid of means with vertical 95% CI bars, with headings rather than visible panel letters and restricted y-axes. |
| Tang H et al., Ann Intern Med 2025;178:315-326 (target trial emulation) | Figure 1 is the cohort flow diagram, from source population through exclusions to two comparisons and 1:1 matching. Figure 2 has two stacked panels of rising cumulative incidence (y-axis 0 to 0.15, 2 years). Each panel has a table below of cumulative events / number at risk and the share still on treatment at 0.5-year steps, and the key sits inside at the upper left. Figure 3 is a forest plot with squares and CI lines, a line at HR 1 and a log axis (0.5, 1, 2), with columns for events/patients, rates, HR (95% CI) and interaction P. |
| Montez-Rath ME et al., Ann Intern Med 2024;177:1233-1243 (target trial emulation) | The main figures are stacked bars of restricted mean time and absolute differences in days with 95% CIs, on linear axes with a line at 0. The flow diagram and a falling standardised survival curve (y-axis 0 to 1, no risk table) are in the supplement. |

The main-text curves in these papers all rise, sit on a narrow y-axis and have a number-at-risk table underneath. The flow diagram is Figure 1 unless the figure limit pushes it to the supplement. Ratios are drawn on a log axis with a line at 1, and differences on a linear axis with a line at 0. Lettering is sans serif. Colours vary from paper to paper, because Annals restyles figures.

## How the skill applies this

- **Time-to-event:**
  - Draw `cum_incidence_png()` from `templates/cum_incidence.R`, from the same population and weights the model used.
  - Put `cum_incidence_diff()` through `table_png()` at fixed times, such as each year.
  - Use the analysis's own CIs (bootstrap, matched) in that table when it has them.
  - From a CohortMethod study population: `time` is `survivalTime` (days; divide by 365.25 for years), `event` is `outcomeCount > 0`, `group` is `treatment` with 1 first, and `cluster` is `stratumId`. With variable-ratio matching, give the treated weight 1 and each comparator in a stratum n treated / n comparator. `plotKaplanMeier` weights its adjusted curves the same way.
- **Forest plots:** use a log axis for ratios with a line at 1, a linear axis for differences with a line at 0, and the supporting numbers per group in the columns (events / persons for a binary outcome, n with a mean or median for a continuous one).
- **Other graphs:** no pie charts, no 3-D, no bars that hide variability; say whether an interval is an SD, a range or a CI. Use a table when a chart adds nothing (skill rule 3).
- **Colour:** Annals charges nothing for colour. In a survey of 35 curve figures from 2023-2026 papers, made for this skill in November 2026 (`curve_colours.md` lists every figure), Annals mostly drew two black lines, solid and dashed (11 of 15). NEJM, JAMA and BMJ paired orange with blue, dark teal, grey or purple, and the Lancet used blue with red. The template's default is Okabe-Ito vermilion `#D55E00` for the target arm and blue `#0072B2` for the comparator, with 1.1 lines, the same way round as CohortMethod's propensity-score plot. Both have at least 3:1 contrast on white (3.9:1 and 5.2:1), the usual minimum for lines, and red-green colour-blind viewers can tell them apart; still check the slides on the projector you will use. ggplot2's default hues for two groups are paler (2.7:1 and 2.3:1). For a paper, `colours = c("black", "black"), linetypes = c("solid", "dashed")` gives the Annals look, and Annals restyles figures anyway.
- **Abbreviations:** in a paper they go in the legend. On a slide they go in a grey note line under the figure (`table_png(..., notes =)` or `D.cap`).
- **Flow diagram:** in a study of participants, draw it in R as the first figure, following the design's guideline above. For a longitudinal database study, the design diagram (`templates/design_diagram.R`, in the colours of Schneeweiss et al. 2019: cyan assessment windows, grey-blue washout, navy covariates, dark navy exposure, green hatched follow-up) comes next.
- **Exporting for submission:** draw the figures as PDF (vector) or TIFF. Slides keep PNG.

## Sources

- Annals Information for Authors: https://www.acpjournals.org/journal/aim/authors (PDF dated 2026-09-16)
- Preparing Manuscripts for Submission: https://www.acpjournals.org/journal/aim/authors2
- General Statistical Guidance: https://www.acpjournals.org/journal/aim/authors/statistical-guidance
- Submission system instructions: https://annals.msubmit.net/cgi-bin/main.plex?form_type=display_auth_instructions
- TARGET checklist and flow templates: https://target-guideline.org/
- STROBE explanation (Annals 2007): https://www.acpjournals.org/doi/10.7326/0003-4819-147-8-200710160-00010-w1
- CONSORT 2025: https://pmc.ncbi.nlm.nih.gov/articles/PMC11996237/
- RECORD: https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1001885

acpjournals.org returns a Cloudflare 403 to plain fetches; the pages open in a real browser.
