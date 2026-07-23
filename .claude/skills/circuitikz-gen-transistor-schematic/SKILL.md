---
name: circuitikz-gen-transistor-schematic
description: Generate or fix a transistor-level analog circuit schematic in CircuitikZ from an xschem .sch netlist (+ optional reference PNG/sketch), with correct MOSFET gate/drain/source placement. Use when creating a new media/*.tex transistor schematic from an analog-db circuit, or when a rendered schematic looks wrong — devices that look boxed-in, wires that appear to run through a transistor body, or drain/source that look shorted.
---

# CircuitikZ transistor-schematic generation

## Overview

Workflow + hard-won gotchas for turning an xschem schematic (`analog-db/**/*.sch`)
into a hand-built, from-scratch CircuitikZ transistor-level diagram under
`media/`. Built from authoring and debugging
[`media/integrator-switchcap-opamp.tex`](../../../media/integrator-switchcap-opamp.tex)
— a fully-differential telescopic-cascode OTA with CMFB bias, 16 devices. Keep
this file and its `references/` up to date: every new schematic that surfaces a
new gotcha (new device family, a layout trick, a circuitikz quirk) should get a
short dated entry in the **Changelog** section at the bottom.

This is for the *mechanical, from-a-real-netlist* schematics (every block is a
known transistor with known connections) — not the paper's higher-level hero
figures (system diagrams, hierarchy views), where CLAUDE.md and the
`figures-reserve-sketch-slots` convention call for leaving placeholders for
hand-drawn content instead of generating full detail.

## Inputs

1. **The xschem `.sch` file** — ground truth for *what connects to what* and
   *device sizes*. Path convention in this repo:
   `analog-db/drawings/<block>/…sch` (the hand-authored source) and/or
   `analog-db/circuits/<circuit>/pdk/<pdk>/schematic/…sch` (the PDK instance)
   — cite both in the `.tex` header comment if they resolve to the same
   circuit, as the existing file does.
2. **A reference PNG/sketch** (if the user supplies one) — ground truth for
   *how it should look*: overall left-to-right flow, which sub-blocks group
   visually, label placement. Never invent connectivity from a PNG that
   isn't backed by the `.sch`; use it only to guide layout/orientation
   choices when the `.sch`'s raw coordinates would be visually awkward.
3. **The existing `.tex` file being fixed** (if debugging), or the nearest
   sibling schematic in `media/` (as a style template).

## Step-by-step

1. **Parse the `.sch`.** Run
   `python3 .claude/skills/circuitikz-gen-transistor-schematic/scripts/parse_xschem_sch.py <file.sch>`
   to get a clean, sorted device list (name, symbol, W/L, position, xschem
   rot/flip) and a labeled-net list with bounding boxes, instead of reading
   the raw text by hand. Y is pre-negated in the output so it already reads
   "larger y = higher," matching circuitikz — **xschem's own Y axis is
   flipped relative to TikZ** (more negative xschem-Y = higher on the page);
   don't forget this if you ever read the raw file directly. A net's bbox
   size is a quick hint: wide/tall bboxes are usually rails or buses
   (VDD/VSS, a tail node shared by many devices); tiny bboxes are usually a
   local gate tie between two adjacent devices.

   The script does **not** attempt pin-level auto-wiring (matching a wire
   endpoint to a specific device pin) — that needs per-symbol pin-offset
   tables that vary by PDK symbol, and would be fragile. Cross-reference the
   device list and net list by eye/domain knowledge (or ask: does this net's
   bbox touch this device's `(x,y)`?) — for a differential-pair/cascode OTA
   this is usually immediate from the topology description already in the
   original prose or the paper draft.

2. **Group devices into rows/columns.** A cascode OTA is naturally a grid:
   rows = stages (tail → diff pair → cascode → current source), columns =
   the two (or more) parallel branches. Pick round-number circuitikz
   coordinates (e.g. 2 units per stage vertically, matching column x's
   across rows) rather than transcribing the `.sch`'s raw pixel-ish
   coordinates — the xschem layout is a hint for grouping and left/right
   order, not a coordinate system to copy verbatim.

3. **Place `\node[pmos/nmos, <transform>]`, get the transform right.**
   **This is the step that actually goes wrong.** Read
   [`references/mos-anchor-cheatsheet.md`](references/mos-anchor-cheatsheet.md)
   before placing any PMOS. Short version: G sits to one side at mid-height;
   D and S both sit on the node's own vertical centerline, one above and
   one below center. For any vertical stack where current flows one
   consistent direction, **only ever use *(no transform)* or `xscale=-1`**
   to choose which side the gate faces — `yscale=-1` and `rotate=180` both
   silently swap D and S vertically (this is *especially* a trap for PMOS,
   whose base orientation is D=bottom/S=top, opposite of NMOS's
   D=top/S=bottom). Getting this wrong doesn't break the netlist — it makes
   the wire between two stacked devices run from the *far* pin of one to
   the *far* pin of the next, straight through both bodies, which reads as
   a shorted drain/source.

   If you introduce a device type not on that cheat sheet (depletion
   devices, BJTs, a bulk-explicit 4-terminal symbol), rebuild
   [`references/anchor-probe.tex`](references/anchor-probe.tex) with the new
   node(s) and read the printed numeric anchors — don't guess from the
   rendered picture, and don't skip this because "it looks right"; the
   whole point of the OTA bug is that a wrong-but-plausible-looking wire
   compiles cleanly and only shows itself on close visual inspection.

4. **Wire the stack via the *facing* anchors**, not the far ones: upper
   device's bottom pin (whichever of D/S that is, per the cheat sheet) to
   lower device's top pin, so the connecting wire only spans the small gap
   between symbols. Route external pins off `.G` with
   `++(dx,0) node[ocirc]{} node[left/right]{$v_\text{...}$}`. Add net labels
   at the wire's midpoint with a light `netlbl` style
   (`node[netlbl,pos=0.5,left/right]{netN}`) using the **exact xschem net
   name** — never invent a label. Add device labels with a `devlbl` style
   near (not on) the symbol.

5. **Compile and visually verify — every time, before calling it done.**
   Per CLAUDE.md, never bare `latexmk -pdf <file>` in the repo root:
   ```
   latexmk -pdf -interaction=nonstopmode -halt-on-error -output-directory=.build <file>.tex
   ```
   Rasterize (`pdftoppm -png -r 200 <file>.pdf out`), then **Read the PNG**.
   Don't stop at a whole-page glance — that's how the box-shaped
   drain/source overlap in the OTA file went unnoticed initially. Crop
   tightly around every stacked junction and re-Read:
   ```
   magick out-1.png -crop <W>x<H>+<X>+<Y> crop.png
   ```
   Look specifically for: a wire that appears to run *through* a
   transistor's own body from one far terminal to the other (the exact bug
   this skill exists to catch), gate lines crossing unrelated wires, label
   collisions. Do this at higher `-r` (e.g. 400) if anything looks
   ambiguous at 200.

6. **Clean up.** Build artifacts belong in the scratchpad or `.build/`
   (git-ignored), never left in the repo — see CLAUDE.md's build-hygiene
   rules. Remove any throwaway test `.tex`/`.pdf`/`.png` files you made
   while iterating.

## Style conventions (match the existing files)

- `\documentclass[border=3mm]{standalone}`, `\usepackage{circuitikz}`,
  `\ctikzset{tripoles/mos style/arrows, transistors/scale=1}`.
- `netlbl` style: gray (`netgray`, `gray!45`), `\scriptsize\itshape` — for
  xschem net names (net1, net2, …) placed at wire midpoints.
- `devlbl` style: plain `\scriptsize` — for device names (M1, M2, …) placed
  just outside the symbol.
- Header comment block: cite the exact `.sch` path(s) this transcribes,
  note the PDK/device family and W/L convention, and describe the topology
  in prose (tail → pair → cascode → … ) as a comment — this is what makes
  the file re-checkable against the source later and mirrors CLAUDE.md's
  grounding requirement even for a supporting asset, not just paper prose.
- Devices keep their netlist names (M1..Mn); nets keep their xschem labels.
  Never rename either for "readability."

## Reference files

- [`references/mos-anchor-cheatsheet.md`](references/mos-anchor-cheatsheet.md) —
  the verified G/D/S-per-transform table and the rule for picking a
  transform; read this before placing any MOSFET.
- [`references/anchor-probe.tex`](references/anchor-probe.tex) — standalone
  CircuitikZ file that numerically prints anchor coordinates
  (`\pgfpointanchor` + `\pgfgetlastxy`); rebuild it to check a device
  type/transform combo not yet in the cheat sheet.
- [`scripts/parse_xschem_sch.py`](scripts/parse_xschem_sch.py) — stdlib-only
  parser that summarizes an xschem `.sch`'s device instances and labeled
  nets; run it first on any new `.sch` instead of reading the raw text.

## Changelog

- **2026-07-23** — Skill created after fixing
  `media/integrator-switchcap-opamp.tex`: all 10 PMOS nodes used
  `yscale=-1`/`rotate=180`, silently swapping D/S and drawing wires through
  transistor bodies (looked like shorted drain/source). Fixed by using only
  *(none)*/`xscale=-1` on every PMOS. Added the anchor cheat sheet, the
  numeric probe template, and the xschem `.sch` parser script.
