#!/usr/bin/env bash
# gen-draft.sh — compile the paper and archive a numbered, dated snapshot
#                into pdf/<title>-<NNNN>-<YYYYMMDD>-<slug>.pdf
#
# Usage: ./scripts/gen-draft.sh [-t <title>] <slug> [draft-id]
#   <slug>          required short description of the draft (e.g. intro-rework).
#   [draft-id]      optional explicit id used verbatim (skips auto counter+date),
#                   e.g. rc1  ->  pdf/<title>-rc1-<slug>.pdf
#   -t, --title     output name prefix; defaults to $TITLE below. Override per run.
#
# Auto id = <counter>-<date>, where <counter> is one past the highest existing
# auto-numbered draft with the SAME title in pdf/ (padded to 4 digits).
set -euo pipefail

# --- defaults (edit here) -----------------------------------------------------
TITLE="paper"              # default paper title / output-name prefix — rename per project
MAIN="paper-main"          # source: compiles $MAIN.tex, i.e. paper-main.tex
OUTDIR="pdf"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

usage() { echo "usage: $0 [-t <title>] <slug> [draft-id]" >&2; }

# --- args ---------------------------------------------------------------------
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--title)     [[ $# -ge 2 ]] || { echo "error: $1 needs a value" >&2; exit 2; }
                    TITLE="$2"; shift 2 ;;
    -t=*|--title=*) TITLE="${1#*=}"; shift ;;
    -h|--help)      usage; exit 0 ;;
    --)             shift; POSITIONAL+=("$@"); break ;;
    -*)             echo "error: unknown option $1" >&2; usage; exit 2 ;;
    *)              POSITIONAL+=("$1"); shift ;;
  esac
done
set -- "${POSITIONAL[@]}"

if [[ $# -lt 1 || -z "${1:-}" ]]; then usage; exit 2; fi

# normalize a free-form label to a filesystem-safe kebab-case token
slugify() { printf '%s' "$1" \
  | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | tr -s '-' | sed 's/^-//; s/-$//'; }

TITLE="$(slugify "$TITLE")"
SLUG="$(slugify "$1")"
[[ -n "$TITLE" ]] || { echo "error: title is empty after normalization" >&2; exit 2; }
[[ -n "$SLUG"  ]] || { echo "error: slug is empty after normalization"  >&2; exit 2; }

[[ -f "$MAIN.tex" ]] || { echo "error: $MAIN.tex not found in $ROOT" >&2; exit 1; }
mkdir -p "$OUTDIR"

# --- draft id -----------------------------------------------------------------
if [[ -n "${2:-}" ]]; then
  DRAFT_ID="$2"                       # explicit id, used as-is
else
  # highest existing auto counter for THIS title in pdf/<title>-<NNNN>-... .pdf, then +1.
  # trailing `|| true` keeps an empty pdf/ (ls fails under pipefail) from aborting.
  last="$(ls "$OUTDIR/${TITLE}"-[0-9]*.pdf 2>/dev/null \
          | sed -E "s|.*/${TITLE}-0*([0-9]+)-.*|\1|" \
          | sort -n | tail -1 || true)"
  next=$(( ${last:-0} + 1 ))
  DRAFT_ID="$(printf '%04d-%s' "$next" "$(date +%Y%m%d)")"
fi

NAME="${TITLE}-${DRAFT_ID}-${SLUG}"
WORKDIR="$OUTDIR/$NAME"                 # per-draft build artifacts live here
OUT="$OUTDIR/$NAME.pdf"                 # flat deliverable, sibling to WORKDIR
mkdir -p "$WORKDIR"

# --- compile (latexmk drives pdflatex + bibtex + reruns; -outdir keeps root clean) ---
echo ">> compiling $MAIN.tex -> $WORKDIR/ ..."
BUILD_LOG="$(mktemp)"
if ! latexmk -pdf -outdir="$WORKDIR" \
       -interaction=nonstopmode -halt-on-error -file-line-error "$MAIN" \
       >"$BUILD_LOG" 2>&1; then
  echo "error: compile failed — last 30 lines:" >&2
  tail -n 30 "$BUILD_LOG" >&2
  rm -f "$BUILD_LOG"
  exit 1
fi
rm -f "$BUILD_LOG"

# --- archive: move the PDF up to the flat deliverable; artifacts stay in WORKDIR ---
mv -f "$WORKDIR/$MAIN.pdf" "$OUT"
echo ">> wrote $OUT (build artifacts in $WORKDIR/)"
