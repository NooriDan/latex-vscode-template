# CLAUDE.md — <paper repo name>

Guidance for Claude Code working in this repo: the LaTeX write-up of
**<paper title>**. It is a *paper repo*, not code — the deliverable is a PDF.
For the compile/draft workflow and the template origin, see
[README.md](README.md).

**Paper:** <title> — <authors> (<institution>). PRIME AI / arxiv style. The
live document is [paper-main.tex](paper-main.tex).

> This file is a starting point copied from a template repo. Fill in the
> bracketed placeholders above (and anywhere else in this file) for the
> specific paper, and trim any section below that doesn't apply. See
> "Bootstrapping a new paper from this template" at the bottom for the full
> checklist.

## Your role

AI help on this repo covers **language, LaTeX mechanics, and the
figure/data pipeline**: grammar, clarity, word choice, tightening prose,
fixing references/labels, table/listing formatting, maintaining figure
sources, and outline/structure work when asked. The hard rules below bind
regardless.

- **Do not invent technical content.** Numbers, results, method details, and
  claims are facts about real work. Never fabricate or "round" them, and
  never introduce a new claim the author hasn't made. If prose needs a
  number you don't have, leave a `% TODO` — don't guess.
- **Every factual claim must be grounded in the actual project** — its code,
  data, experiments, or the author's own statements — not in general
  domain knowledge. When you can't verify a claim against a real source,
  flag it rather than assert it.
- **Citations are real or absent.** Never invent authors, venues, or DOIs;
  mark a needed-but-unknown reference with `% TODO: cite`. See *Finding and
  adding references* below for the procedure.
- **Preserve the authors' voice and argument.** Make surgical edits; don't
  rewrite a paragraph's thesis or reorder the contribution list unless
  asked. If the draft uses an outline convention (e.g. `% ARC:` comments,
  threaded requirement/RQ labels), fill within it, don't replace it.
- Keep changes reviewable: **don't reflow/rewrap untouched lines.** The
  `.tex` is hand-wrapped; editor format-on-save is scoped to `.bib` only
  (see `.vscode/`), so large whitespace-only diffs are on you to avoid.

## Finding and adding references

Default workflow: `references.bib` is downstream of the author's **Zotero**
library, so you do not write BibTeX entries into it directly. Splitting the
work: you find and verify the source and cite it; the author imports it into
Zotero and exports the entry. (If this paper doesn't use Zotero, ask the
author how they want new entries added, and update this section.)

1. **Find candidates.** Web search is fine for discovery but too loose to
   cite from. Confirm every candidate against the **Crossref API**, which
   returns authoritative metadata and the real DOI:

   ```sh
   curl -s 'https://api.crossref.org/works?query.bibliographic=<terms>&rows=5' \
     | python3 -c "import json,sys; [print(i['DOI'],'|',i['title'][0]) for i in json.load(sys.stdin)['message']['items']]"
   curl -s 'https://api.crossref.org/works/<doi>'   # full metadata for one DOI
   ```

   A search-engine snippet is not verification. If Crossref does not resolve
   it, the reference does not go in.
2. **Cite it in `paper-main.tex`** using a key you generate (see below), and
   **report the DOI plus full verified metadata** (authors, venue,
   volume/issue, pages, year) to the author so they can add it to Zotero.
3. **Leave `references.bib` alone** once the project has a real Zotero (or
   equivalent) export flow — adding the entry yourself would collide with
   it. Until it's exported, `latexmk` reports the new key as an undefined
   citation — that is the expected intermediate state, not a failure. Say
   which undefined keys are yours so a real one is never mistaken for noise.
4. **Check the title actually supports the claim.** A cite is wrong if the
   paper's own title or abstract contradicts how the prose describes it.
   Flag the mismatch rather than smoothing over it.

**Bib key convention:** mirror whatever scheme is already in use in this
paper's `references.bib` — don't invent a new one. A common pattern is
`<topic>_<tag>_<citekey>`, where `<citekey>` matches the reference
manager's own key (e.g. `authorTitleWordYear`).

## Layout

| Path | What it is |
|---|---|
| `paper-main.tex` | the paper — the only source file you normally edit |
| `PRIMEarxiv.sty` | active style package (arxiv style by George Kour, adapted for PRIME); identical to `template/PRIMEarxiv.sty` |
| `references.bib` | bibliography (fill as you cite; entries must be genuine) |
| `media/` | built figure PDFs, where `\graphicspath` resolves (create as needed) |
| `media/src/` | figure sources — standalone TikZ, plot scripts (create as needed) |
| `template/` | the pristine arxiv/PRIME template (`templatePRIME.tex` + `.sty`) — reference only, not part of the build |
| `scripts/` | `gen-draft.sh` (compile + archive a snapshot), `clean-build.sh` (purge build artifacts) |
| `.vscode/settings.json` | LaTeX Workshop config: builds to `build/`, ChkTeX lint, `.bib` format-on-save |
| `academic-writing-skill/` | git submodule pinning [NooriDan/academic-writing-skill](https://github.com/NooriDan/academic-writing-skill) — the actual skill sources live here |
| `.claude/skills/` | **symlink** to `academic-writing-skill/skills` (see below) — empty/broken until `git submodule update --init` has run |

## Building

`latexmk -pdf` is the engine. Three paths, each with its own output
directory so they never clobber each other:

- **Editor:** VS Code + LaTeX Workshop builds into `build/` (on demand,
  Ctrl+Alt+B).
- **Snapshot a draft:** `./scripts/gen-draft.sh [-t <title>] <slug> [draft-id]`
  compiles and archives `pdf/<title>-<NNNN>-<YYYYMMDD>-<slug>.pdf`
  (artifacts in a sibling dir). Clean up with `./scripts/clean-build.sh`.
- **Compile check (your default):** always redirect output to `.build/`:

  ```sh
  latexmk -pdf -interaction=nonstopmode -halt-on-error -output-directory=.build paper-main.tex
  ```

  **Never run a bare `latexmk -pdf paper-main`** — it litters the repo root
  with `paper-main.pdf` and aux files and stomps on whatever the editor has
  in `build/`. `.build/` is git-ignored and `clean-build.sh` deletes it
  wholesale, so it is disposable; the `.githooks/pre-commit` hook uses
  `.precommit-build/` the same way. The same applies to any
  `.build-<figid>/` scratch dir used to compile-check a standalone figure on
  its own (e.g. `.build-f3/`) — glob-matched by `.build*/` in both
  `.gitignore` and `clean-build.sh`.

Build artifacts (`*.aux`, `*.log`, `build/`, `.build/`, per-draft dirs, …)
are git-ignored; **archived PDFs under `pdf/` are tracked**. Never commit
stray aux/log files. After editing, a compile check as above (or a
`gen-draft.sh` run) is the way to confirm the paper still compiles — do that
before claiming an edit is done. `make check` runs the same check over every
`.tex` source in the repo (see the Makefile).

**Figures:** every float should be built from a real vector source (TikZ,
SVG, matplotlib), not a screenshot. As the figure count grows, consider a
plan-and-tracker file (e.g. `media/figures.md`: id, section, status, asset
path, data source) so floats stay auditable — introduce one once it earns
its keep, don't pre-create it empty.

## Skills available in this repo

`.claude/skills/` is a symlink into the `academic-writing-skill/` submodule
(see *Layout*) — the skills aren't vendored here, so don't edit them in
place; edit them in the `academic-writing-skill` repo and let the submodule
pin pick up the change (`make submodules` to pull latest, or bump the pin
by committing the new submodule SHA).

- **academic-writing-style** — active voice, punctuation, concision,
  paragraph structure; use when polishing prose.
- **research-paper-writing** — section-level structure and reviewer-facing
  presentation (Abstract/Intro/Related Work/Method/Experiments/Conclusion).
- **circuitikz-gen-transistor-schematic** — generates/fixes CircuiTikZ
  transistor-level schematics from xschem netlists. **Only relevant to
  analog-circuit papers** — harmless to leave for other papers since it
  self-scopes off its own description; it just won't fire.

## Git

**Never `git commit` or `git push` (or open a PR) unless explicitly asked
to in that turn.** Editing files is fine; leave the working tree uncommitted
otherwise so the author can review a diff before it becomes history. A
short-lived `feat/<name>` branch → PR → squash is a reasonable default when
committing is asked for; small edits may go straight to `main` if the
author prefers.

## Bootstrapping a new paper from this template

When starting a new paper from this template, at minimum:

1. Fill in the placeholders at the top of this file (repo name, title,
   authors, institution) and in `paper-main.tex` (`\title`, `\author`).
2. Once per clone: `git submodule update --init` to populate
   `academic-writing-skill/` (and make `.claude/skills/` resolve).
3. Update `LICENSE` (copyright holder/year) and `README.md` (project name,
   description) for the new paper.
4. Set `TITLE` in `scripts/gen-draft.sh` to the new paper's slug.
5. Once per clone: `git config core.hooksPath .githooks` to enable the
   pre-commit compile check.
6. Delete this checklist section once done.
