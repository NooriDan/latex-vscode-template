# circuitikz MOSFET anchor geometry (verified)

Ground truth for where `.G`, `.D`, `.S` land on a circuitikz `nmos`/`pmos`
node under each transform, and which transform to pick for a given desired
orientation. Verified numerically (see `anchor-probe.tex` in this folder) —
don't re-derive this from the rendered picture by eye, and don't trust
intuition about "rotate vs. flip" here; the two families behave
differently for pmos vs nmos, which is exactly the trap this cheat sheet
exists to flag.

## The shape

Every plain `nmos`/`pmos` node has:
- `G` offset **horizontally** from the node center, at mid-height (y=0).
- `D` and `S` both on the node's own **vertical centerline** (x=0),
  one above center, one below.

So a clean vertical stack (cascode column) only looks right if consecutive
devices' `D`/`S` anchors keep the same top/bottom assignment — the wire
between them should span just the small gap, never the whole node height.

## Base (untransformed) orientation

| | G | D | S |
|---|---|---|---|
| `pmos` | left | **bottom** | **top** |
| `nmos` | left | **top** | **bottom** |

PMOS and NMOS are mirrored: this matches physical convention for a
VDD-to-VSS stack (PMOS source toward VDD/up, NMOS drain toward the
upper/output side).

## Effect of each transform

| transform | pmos G | pmos D | pmos S | nmos G | nmos D | nmos S |
|---|---|---|---|---|---|---|
| *(none)* | left | bottom | top | left | top | bottom |
| `xscale=-1` | right | bottom | top | right | top | bottom |
| `yscale=-1` | left | **top** | **bottom** | left | **bottom** | **top** |
| `rotate=180` | right | **top** | **bottom** | right | **bottom** | **top** |

Read the bolded cells as the trap: `yscale=-1` and `rotate=180` **swap**
D/S vertically for *both* device types, relative to that type's own base.

## The rule that actually matters for drawing

In an analog stack (current flows one consistent direction top-to-bottom
through the column), you want D/S to keep their base vertical assignment
on every device in that column, and only the gate side to change so gates
can face a neighbor or an external label. That means:

- **For `pmos`: only ever use *(none)* or `xscale=-1`.** Never `yscale=-1`
  or `rotate=180` — both silently swap D=bottom/S=top to D=top/S=bottom,
  which makes the wire to the device above/below jump to the *far* pin
  instead of the *near* one, drawing straight through the transistor body.
- **For `nmos`: only ever use *(none)* or `xscale=-1`** for the same
  reason (nmos base is D=top/S=bottom; `xscale=-1` preserves that).
- Pick *(none)* when the gate should face **left**, `xscale=-1` when it
  should face **right**. That's the only decision — never reach for
  `yscale`/`rotate` to "flip" a MOSFET in a vertical stack.

`yscale=-1`/`rotate=180` are only correct if you *want* to reverse which
end is D vs S electrically (e.g., drawing current flowing the opposite
way through that one device) — that's rare and should be a deliberate,
commented choice, not a default mirroring habit.

## Case study: the bug this cheat sheet was written from

`media/integrator-switchcap-opamp.tex` originally used `yscale=-1`/
`rotate=180` on **all ten PMOS** nodes (M1–M10) to get their gates facing
the right neighbor, which flipped every one of them to D=top/S=bottom.
Wires like `\draw (M2.D) -- (M9.S);` then connected M2's *top* pin to M9's
*bottom* pin — spanning clean through both transistor bodies — instead of
M2's bottom pin to M9's top pin (the actual small gap between them). It
rendered as a box-shaped overlap that read as "drain and source shorted."
Fixed by swapping every `rotate=180`→`xscale=-1` and every `yscale=-1`→
*(none)*, with zero changes to any `\draw` line, because those already
referenced `.D`/`.S` per the intended physical meaning — only the
transform was wrong. All six NMOS nodes in that file already used
*(none)*/`xscale=-1` and needed no fix.

## Re-verifying (new device types, new circuitikz version)

If you introduce a device family not covered above (`nmosd`/`pmosd`
depletion devices, BJTs `npn`/`pnp`, a 4-terminal bulk-explicit variant,
etc.) or circuitikz updates its symbol geometry, don't guess — rebuild
`anchor-probe.tex` in this folder with the new node type(s) and read the
printed coordinates. It's a ~15-line standalone file; compile with
`latexmk -pdf` and `pdftotext` the result, no image inspection needed.
When you learn a new mapping, add a row to the tables above and note the
circuitikz version if it changed behavior.
