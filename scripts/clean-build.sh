#!/usr/bin/env bash
# clean-build.sh — remove LaTeX build artifacts (aux/log/out/synctex/…), verbosely:
# every file/dir removed is printed as it goes.
#
# Usage:
#   ./scripts/clean-build.sh          # all clean: repo root (top level), build/, every throwaway
#                                     #   .build*/ scratch dir (.build/, .build-f3/, ...) and
#                                     #   .precommit-build/, and everything under pdf/
#   ./scripts/clean-build.sh <dir>    # clean <dir> recursively (and drop it if it empties out)
#
# Sources (.tex/.bib/.sty) and deliverable PDFs (pdf/*.pdf) are never touched —
# only regenerable build artifacts are removed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"
OUTDIR="pdf"

# artifact extensions to purge — note: .pdf is NOT here, so PDFs survive
EXTS=(aux bbl blg bcf fdb_latexmk fls log out run.xml synctex.gz synctex
      toc lof lot nav snm vrb idx ilg ind pyg pytxcode)
NAME_ARGS=()
for e in "${EXTS[@]}"; do NAME_ARGS+=( -o -name "*.$e" ); done   # "${NAME_ARGS[@]:1}" drops leading -o

# sweep <dir> [maxdepth]: print + delete artifact files; with no maxdepth also prune empty subdirs
sweep() {
  local dir="$1" md="${2:-}"
  [[ -d "$dir" ]] || return 0
  echo ">> sweeping $dir for build artifacts..."
  if [[ -n "$md" ]]; then
    find "$dir" -maxdepth "$md" -type f \( "${NAME_ARGS[@]:1}" \) -print -delete \
      | sed 's/^/   removed: /'
  else
    find "$dir" -type f \( "${NAME_ARGS[@]:1}" \) -print -delete \
      | sed 's/^/   removed: /'
    find "$dir" -mindepth 1 -type d -empty -print -delete \
      | sed 's/^/   removed: /; s/$/\/ (now-empty dir)/'
  fi
}

if [[ $# -ge 1 ]]; then
  target="$1"
  [[ -d "$target" ]] || { echo "error: not a directory: $target" >&2; exit 1; }
  sweep "$target"
  if rmdir "$target" 2>/dev/null; then
    echo "   removed: $target/ (now-empty, dropped)"
  fi
  echo ">> cleaned $target (recursive)"
else
  sweep "$ROOT" 1                              # stray artifacts at repo root, top level only
  sweep build                                  # LaTeX Workshop (VSCode) live-build dir, if present
  found_scratch=false
  for d in "$ROOT"/.build*/; do                # agent/CLI compile-check dirs (.build/, .build-f3/, ...)
    [[ -d "$d" ]] || continue                  #   — throwaway, remove whole
    found_scratch=true
    echo ">> removing throwaway scratch dir $d ..."
    rm -rfv "$d" | sed 's/^/   removed: /'
  done
  $found_scratch || echo ">> no .build*/ scratch dirs found"
  if [[ -d "$ROOT/.precommit-build" ]]; then
    echo ">> removing $ROOT/.precommit-build ..."
    rm -rfv "$ROOT/.precommit-build" | sed 's/^/   removed: /'
  fi
  sweep "$OUTDIR"                              # every gen-draft build dir under pdf/, recursively
  echo ">> all clean (repo root + build/ + .build*/ + .precommit-build/ + pdf/); sources and *.pdf kept"
fi
