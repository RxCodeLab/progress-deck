# Review brief for a finished deck

Copy this brief, fill in the parts in angle brackets, and give it to the reviewer (a second model or a colleague) together with the rendered slides (`deck.sh check` writes `slide-NN.png` and the slide text). Its shape follows how Anthropic's Claude Code team runs code review (Osmani A et al., "How the Claude Code team does code review", claude.dev blog, 15 October 2026, https://claude.dev/blog/solving-code-review-at-anthropic/). The reviewer is told what failure looks like and must show evidence for each finding. Findings carry a severity tag, minor wording comments are capped, and the report opens with a count. Each finding is checked before it is applied, and the review stops after three rounds.

---

You are reviewing <n> slide decks for <the audience: an advisor, a clinical collaborator>. They will read them in <a meeting / on their own>. Each deck covers one analysis: <one line per deck: title, folder of rendered slides, slide text file>.

The code that made them is in <folders and files>. The recorded results and definitions are in <documents>. <Files the reviewer must not open, such as patient-level data.>

## What the decks must do

<The user's own rules, which the reviewer should not argue with. The skill's rules 1-13 are a starting point: paper order, R output only, nested tables, the target journal's figure rules, the design diagram style, full citations, abbreviations explained, no working codes, real counts, one colour per arm.>

## What counts as a failure

- A number on a slide that disagrees with another slide or with the recorded results. Name both places.
- A figure or table that shows the wrong population, arm or follow-up, or labels the arms the wrong way round.
- A definition, window or criterion that disagrees with the design documents or the code.
- A citation with a wrong author, journal, year, volume or pages, or one that does not support the fact next to it. Check it against the publisher or PubMed.
- An interpretation that says more than its numbers support, or less.
- Something the audience would have to stop and puzzle over: a vague label, an unexplained abbreviation or term, a table whose structure hides what belongs to what, a missing denominator, a slide out of logical order.
- Layout: text too small to read when projected, a table cut off, overlapping text, space a figure could fill.

## How to report

Start with one line: the number of findings by severity, or "nothing to fix".

Then list the findings, most severe first. Each finding has:
- a tag: **Important** (wrong, misleading, or blocks understanding), **Nit** (wording or polish), or **Pre-existing** (a problem in the analysis itself, not in the deck);
- the deck and slide, and the file and line of the code that makes it when you can find it;
- the evidence: what the slide says and what the source says;
- the fix, in one sentence.

When one fix applies to a type of problem across several slides, report it once and list every slide it applies to. Keep Nits to the 15 that matter most.

---

## After the review

- Check every finding against the source before applying it. Note the rejected ones and why. A reviewer's confident tone is no evidence.
- Fix every instance of a type of problem, not only the slide named.
- Round two and three get only the slides that changed, with the previous report. Stop after three rounds and take what is left to the user.
- If the user later catches something the review missed, add it to the lint in `scripts/inspect_deck.py` or to the rules in `SKILL.md`, so the next deck is checked for it.
