# latex-vscode-template

A starter repo for writing an academic paper in LaTeX with VS Code + LaTeX
Workshop and Claude Code. Click **"Use this template"** on GitHub to start a
new paper repo from this one.

`paper-main.tex` ships in the PRIME AI / arxiv style; `template/` also carries
an IEEEtran skeleton for IEEE venues (see "Switching to IEEEtran"). Around
that: a compile/draft/clean workflow, a pre-commit compile check, CI, and
Claude Code skills for academic writing and figure generation — pulled in live
via a git submodule (`academic-writing-skill/`) rather than vendored copies, so
run `git submodule update --init` after cloning.

## Getting started with a new paper

1. Create your paper repo from this template (GitHub: "Use this template").
2. Clone it, then init the skills submodule:
   ```bash
   git submodule update --init
   ```
3. Edit `paper-main.tex`: set `\title`, `\author`, and start writing.
4. Fill in the placeholders in `CLAUDE.md` and work through its
   "Bootstrapping a new paper from this template" checklist.
5. Enable the pre-commit hook (once per clone):
   ```bash
   git config core.hooksPath .githooks
   ```

## Switching to IEEEtran

`paper-main.tex` starts from the single-column PRIME/arXiv style. For an IEEE
journal or conference, `template/templateIEEE.tex` is the pristine two-column
counterpart — a minimal, compiling IEEEtran skeleton (title/`\thanks`,
`\markboth`, `IEEEkeywords`, `\IEEEPARstart`, IEEE float and bibliography
conventions). Copy it over `paper-main.tex`, or port the preamble delta:

| PRIME / arXiv | IEEE |
|---|---|
| `\documentclass{article}` + `\usepackage{PRIMEarxiv}` | `\documentclass[lettersize,journal]{IEEEtran}` |
| `\usepackage{hyperref}` | `\usepackage[hypertexnames=false]{hyperref}` — avoids IEEEtran's duplicate float anchors |
| `\usepackage{subcaption}` | `\usepackage[caption=false,font=footnotesize]{subfig}` — IEEE's recommended package |
| — | `\usepackage{stfloats}` — lets double-column floats sit at the bottom of a page |
| `\usepackage{fancyhdr}` | drop it; IEEEtran sets the running heads via `\markboth` |
| `\keywords{...}` | `\begin{IEEEkeywords}...\end{IEEEkeywords}` |
| `\author{A \And B}` | one `\author` string with `\IEEEmembership` and `\thanks{}` notes |
| `\bibliographystyle{unsrt}` | `\bibliographystyle{IEEEtran}` |

Also note that the page is two-column: full-width floats need `figure*`/`table*`,
and IEEE puts table captions above the table.

The class itself is **not vendored** — `IEEEtran.cls` and `IEEEtran.bst` ship
with TeX Live/MiKTeX (package `ieeetran`) and with the CI container. Drop a copy
of the `.cls` at the repo root only if a venue pins a version different from
your distribution's; `latexmk` prefers the local file.

## Draft workflow

Compile `paper-main.tex` and archive a snapshot into `pdf/`:

```bash
./scripts/gen-draft.sh [-t <title>] <slug> [draft-id]
```

- `<slug>` — short description of the draft, e.g. `intro-rework` (normalized to kebab-case).
- `[draft-id]` — optional; omit to auto-number, or pass one (e.g. `rc1`) to use it verbatim.
- `-t, --title` — output-name prefix; defaults to `TITLE` in the script.

Each run produces two siblings under `pdf/`:

- `pdf/<title>-<NNNN>-<YYYYMMDD>-<slug>.pdf` — the deliverable (`<NNNN>` is one past the
  highest numbered draft *with the same title*; each title counts separately).
- `pdf/<title>-<NNNN>-<YYYYMMDD>-<slug>/` — that build's artifacts (aux/log/…), keeping the
  repo root clean.

Or use the Makefile:

```bash
make check                 # compile-check every .tex source in the repo
make draft SLUG=<slug>     # same as gen-draft.sh
make clean                 # remove build artifacts
```

Remove build artifacts (sources and `pdf/*.pdf` are always kept):

```bash
./scripts/clean-build.sh          # all clean: repo root + everything under pdf/
./scripts/clean-build.sh <dir>    # clean one directory recursively
```

Build artifacts are git-ignored (`.gitignore`); the archived PDFs under `pdf/` are tracked.

### Pre-commit compile check

A `pre-commit` hook (`.githooks/pre-commit`) recompiles `paper-main.tex` with
`latexmk` before any commit that touches `paper-main.tex`, `references.bib`, a
`.sty`, or anything under `media/`, and blocks the commit on a hard compile
error (bad BibTeX syntax, an unencodable character, etc.). It does **not**
fail on undefined citations/references or missing BibTeX fields — expected
noise in a work-in-progress draft — only on a nonzero `latexmk` exit code.

Enable it once per clone (hooks aren't cloned by default):

```bash
git config core.hooksPath .githooks
```

### CI compile check

`.github/workflows/build-check.yml` mirrors the pre-commit hook on GitHub:
on every push to `main` and every PR touching `paper-main.tex`, `references.bib`,
a `.sty`, or `media/**`, it compiles `paper-main.tex` with `latexmk` in a clean
container and uploads the resulting PDF as a build artifact on success.

## Claude Code integration

`.claude/skills/` is a **symlink** into the `academic-writing-skill/` git
submodule (pinned to
[NooriDan/academic-writing-skill](https://github.com/NooriDan/academic-writing-skill)),
not a flat copy — so every paper repo made from this template shares one
source of truth for its skills and can pull in improvements later. It's
empty until you run `git submodule update --init` (see "Getting started").

Currently ships:

- **academic-writing-style** — sentence/paragraph-level prose revision.
- **research-paper-writing** — section-level structure and reviewer-facing
  presentation.
- **circuitikz-gen-transistor-schematic** — CircuiTikZ transistor schematics
  from xschem netlists, plus `scripts/check_schematic.py`, a stdlib-only linter
  that checks the generated `.tex` against the `.sch` for missing devices and
  wrong junction dots. Only relevant to analog-circuit papers; it self-scopes
  via its own description, so it's harmless to leave in for other papers.

To pull the latest skills from upstream:

```bash
make submodules          # git submodule update --init --remote
```

Plain `git submodule update --init` (no `--remote`) checks out whatever
commit is currently pinned in this repo instead of the latest upstream —
use that if you want a reproducible, pinned skill set rather than always-latest.

`CLAUDE.md` carries the project guidance (hard rules on not inventing
content/citations, the reference-finding workflow, build instructions) —
fill in its placeholders for each new paper.

## Editor setup

`.vscode/settings.json` configures LaTeX Workshop: builds to `build/` (never
auto-builds — Ctrl+Alt+B on demand), ChkTeX linting (`.chktexrc` at repo
root), and format-on-save scoped to `.bib` files only so the `.tex` stays
hand-wrapped.

## Writing resources

- [UC Berkeley SLC — Writing Worksheets and Other Writing Resources](https://slc.berkeley.edu/writing-worksheets-and-other-writing-resources)

---

# Arxiv Template Guide

## Description

1. Template for the Perception, Robotics and Intelligent Machines (PRIME)
   research group, Université de Moncton, Canada (`templatePRIME.tex`).
   https://primeai.ca/
2. Can also be used as a plain Arxiv template.

Adapted by Moulay Akhloufi using the Arxiv style of George Kour, available at
https://github.com/kourgeorge/arxiv-style (last accessed: April 2021).

George Kour's Arxiv style is provided under an MIT License (Copyright (c)
2020 George Kour; permission is hereby granted, free of charge, to any
person obtaining a copy of this software and associated documentation files
(the "Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions).

## Instructions

1. For a PRIME AI paper, use `templatePRIME.tex` with `PRIMEarxiv.sty` (this
   is what `paper-main.tex` at the repo root starts from).
2. For an IEEE paper, use `templateIEEE.tex` (see "Switching to IEEEtran"
   above); it needs no `.sty` from this repo.
3. `template/` keeps a pristine, untouched copy of each template for
   reference — it isn't part of the build.
