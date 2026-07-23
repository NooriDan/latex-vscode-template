.PHONY: help check check-all draft clean clean-all

MAIN    := paper-main
BUILDIR := .build

# Every .tex source meant to compile on its own: paper-main.tex plus any standalone
# figures under media/ (excludes template/ and .claude/ reference-only sources,
# and any build/.build*/pdf scratch dirs).
TEXFILES := $(shell find . \( -path './template' -o -path './.claude' -o -path './.git' \) -prune -o \
              -name '*.tex' -not -path '*/build/*' -not -path './.build*/*' -not -path './pdf/*' -print \
              | sed 's|^\./||' | sort)

help:
	@echo "targets:"
	@echo "  make check                 compile-check every .tex source (see FILE= to narrow)"
	@echo "                             optional: FILE=<path/to/one.tex>"
	@echo "  make check-all             compile-check every .tex source, ignoring any FILE="
	@echo "  make draft SLUG=<slug>     compile + archive a snapshot into pdf/ (./scripts/gen-draft.sh)"
	@echo "                             optional: TITLE=<title> DRAFT_ID=<id>"
	@echo "  make clean                 remove build artifacts (./scripts/clean-build.sh)"
	@echo "  make clean-all DIR=<dir>   remove build artifacts under one directory, recursively"

# Shared loop body for check/check-all: $(1) is the list of .tex files to compile.
# paper-main.tex builds into $(BUILDIR)/; every other .tex (a standalone figure) builds
# into its own throwaway .build-<slug>/ (see CLAUDE.md's .build*/ scratch-dir convention).
# Quiet per file on success; full log kept alongside each build, tailed on failure.
define CHECK_LOOP
fail=0; \
for f in $(1); do \
  if [ ! -f "$$f" ]; then echo "error: no such file: $$f" >&2; exit 2; fi; \
  if [ "$$f" = "$(MAIN).tex" ]; then outdir="$(BUILDIR)"; \
  else slug=$$(basename "$$f" .tex | tr '[:upper:]' '[:lower:]'); outdir=".build-$$slug"; fi; \
  mkdir -p "$$outdir"; \
  log="$$outdir/check.log"; \
  printf '>> compiling %s -> %s/ ... ' "$$f" "$$outdir"; \
  if latexmk -pdf -interaction=nonstopmode -halt-on-error \
       -output-directory="$(CURDIR)/$$outdir" "$$f" >"$$log" 2>&1; then \
    echo "ok"; \
  else \
    echo "FAILED"; \
    echo "error: $$f failed to compile -- last 30 lines of $$log:" >&2; \
    tail -n 30 "$$log" >&2; \
    fail=1; \
  fi; \
done; \
exit $$fail
endef

# Default compile check — see CLAUDE.md ("Building"). Never run a bare `latexmk -pdf paper-main`.
# Narrow to one file with: make check FILE=media/some-figure.tex
check:
	@$(call CHECK_LOOP,$(if $(FILE),$(FILE),$(TEXFILES)))

# Always checks every .tex source, even if FILE= is set in the environment.
check-all:
	@$(call CHECK_LOOP,$(TEXFILES))

# make draft SLUG=intro-rework [TITLE=my-paper] [DRAFT_ID=rc1]
draft:
	@if [ -z "$(SLUG)" ]; then echo "error: SLUG is required, e.g. make draft SLUG=intro-rework" >&2; exit 2; fi
	./scripts/gen-draft.sh $(if $(TITLE),-t $(TITLE)) $(SLUG) $(DRAFT_ID)

clean:
	./scripts/clean-build.sh

clean-all:
	@if [ -z "$(DIR)" ]; then echo "error: DIR is required, e.g. make clean-all DIR=pdf/some-draft" >&2; exit 2; fi
	./scripts/clean-build.sh $(DIR)
