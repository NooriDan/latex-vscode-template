#!/usr/bin/env python3
"""Summarize an xschem .sch file: device instances + labeled net segments.

Usage: python3 parse_xschem_sch.py <file.sch>

xschem's Y axis is flipped vs. TikZ/circuitikz (more negative Y = higher on
the page). Y values below are printed negated so they read directly as
"larger y = higher" like a circuitikz coordinate.

This is a reading aid, not a code generator: it turns the raw .sch text into
a sorted device list (top-to-bottom, matching the visual stack) and a net
list with bounding boxes (a tall/wide bbox usually means a bus or shared
rail; a tiny bbox usually means a local gate tie). Use it to plan the
circuitikz layout and to cross-check net names against what you draw --
never to auto-place nodes (see SKILL.md for why pin-level auto-inference
isn't attempted here).
"""
import re
import sys
from collections import defaultdict

C_RE = re.compile(
    r'^C \{([^}]*)\}\s+(-?\d+)\s+(-?\d+)\s+(\d+)\s+(\d+)\s+\{([^}]*)\}', re.M)
N_RE = re.compile(
    r'^N\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+\{([^}]*)\}', re.M)


def parse(path):
    text = open(path).read()
    devices = []
    for sym, x, y, rot, flip, props in C_RE.findall(text):
        if 'title.sym' in sym or 'pin.sym' in sym:
            continue  # skip title block and I/O pin markers
        name = re.search(r'name=(\S+)', props)
        w = re.search(r'\bw=(\S+)', props)
        l = re.search(r'\bl=(\S+)', props)
        devices.append({
            'name': name.group(1) if name else '?',
            'symbol': sym.rsplit('/', 1)[-1],
            'x': int(x), 'y': -int(y),
            'rot': rot, 'flip': flip,
            'w': w.group(1) if w else None,
            'l': l.group(1) if l else None,
        })
    nets = defaultdict(list)
    for x1, y1, x2, y2, props in N_RE.findall(text):
        lab = re.search(r'lab=(\S+)', props)
        if lab:
            nets[lab.group(1)].append((int(x1), -int(y1), int(x2), -int(y2)))
    return devices, nets


def main():
    if len(sys.argv) != 2:
        sys.exit(f"usage: {sys.argv[0]} <file.sch>")
    devices, nets = parse(sys.argv[1])

    print(f"# {len(devices)} device instances (sorted top-to-bottom, left-to-right)")
    for d in sorted(devices, key=lambda d: (-d['y'], d['x'])):
        size = f"  W/L={d['w']}/{d['l']}" if d['w'] else ""
        print(f"  {d['name']:<6} {d['symbol']:<22} at ({d['x']:>5},{d['y']:>5})"
              f"  rot={d['rot']} flip={d['flip']}{size}")

    print(f"\n# {len(nets)} labeled nets (bbox in translated/up-positive coords)")
    for lab, segs in sorted(nets.items()):
        xs = [x for s in segs for x in (s[0], s[2])]
        ys = [y for s in segs for y in (s[1], s[3])]
        print(f"  {lab:<14} {len(segs):>2} segment(s)  "
              f"x[{min(xs):>5},{max(xs):>5}]  y[{min(ys):>5},{max(ys):>5}]")


if __name__ == '__main__':
    main()
