"""Check the dome's geometry, its build schedule, and that every socket fits.

usage: python3 tests/test_dome.py [OPENSCAD]

1. The geodesic sphere behind each dome has 10F^2 + 2 vertices and 30F^2
   edges at frequency F (Euler's formula for a subdivided icosahedron).
2. The 2V and 3V (5/8) dome schedules and the 4V chord factors match the
   published tables for icosahedral class I domes.
3. At 2V and 3V, each hub placed on the dome is tested against every strut at its
   cut length: struts 0.5 mm thinner than the bore touch no hub, and struts
   0.5 mm thicker hit every socket of the hub they belong to.
4. Every hub type at 2V to 4V renders as one piece with --hardwarnings, with
   octagonal and with round sockets.
5. In every hub type at 1V to 4V, neighbouring bores keep at least one wall
   between them.
"""

import os
import re
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOME = os.path.join(ROOT, "geodesic_dome.scad")
SCHEDULE = os.path.join(ROOT, "tests", "schedule.scad")
FIT = os.path.join(ROOT, "tests", "fit.scad")

# Published chord factors and counts, radius 1.
PUBLISHED = {
    2: {"points": 26, "struts": 65, "chords": [(0.54653, 30), (0.61803, 35)],
        "hubs": [(5, 6), (6, 10), (4, 10)]},
    3: {"points": 61, "struts": 165, "chords": [(0.34862, 30), (0.40355, 55), (0.41241, 80)]},
    4: {"chord_factors": [0.25318, 0.29453, 0.29524, 0.29859, 0.31287, 0.32492]},
}


def run(openscad, scad, out, defines, export="binstl"):
    cmd = [openscad, "--hardwarnings", "--export-format", export, "-o", out]
    for name, value in defines.items():
        cmd += ["-D", f"{name}={value}"]
    return subprocess.run(cmd + [scad], capture_output=True, text=True)


def echoes(openscad, tmp, frequency):
    out = os.path.join(tmp, "schedule.echo")
    result = run(openscad, SCHEDULE, out, {"frequency": frequency}, export="echo")
    if result.returncode != 0:
        raise RuntimeError(f"schedule.scad at {frequency}V: {result.stderr.strip()}")
    lines = open(out).read().splitlines()
    nums = {k: float(v) for line in lines for k, v in re.findall(r"(\w+) = (-?[\d.]+)(?=,|$)", line)}
    hub_line = next(l for l in lines if l.startswith("ECHO: hubs = "))
    strut_line = next(l for l in lines if l.startswith("ECHO: struts = "))
    hubs = [(int(a), int(b)) for a, b in re.findall(r"\[(\d+), (\d+)\]", hub_line)]
    chords = [(float(a), int(b)) for a, b in re.findall(r"\[([\d.]+), (\d+)\]", strut_line)]
    return nums, hubs, chords


def volume(path):
    data = open(path, "rb").read()
    (n,) = struct.unpack_from("<I", data, 80)
    v = 0.0
    for i in range(n):
        a = struct.unpack_from("<9f", data, 84 + i * 50 + 12)
        p, q, r = a[0:3], a[3:6], a[6:9]
        v += (p[0] * (q[1] * r[2] - q[2] * r[1]) - p[1] * (q[0] * r[2] - q[2] * r[0])
              + p[2] * (q[0] * r[1] - q[1] * r[0])) / 6
    return abs(v)


def solids(path):
    data = open(path, "rb").read()
    (n,) = struct.unpack_from("<I", data, 80)
    parent = {}

    def find(v):
        while parent[v] != v:
            parent[v] = parent[parent[v]]
            v = parent[v]
        return v

    for i in range(n):
        a = struct.unpack_from("<9f", data, 84 + i * 50 + 12)
        corners = [a[0:3], a[3:6], a[6:9]]
        for c in corners:
            parent.setdefault(c, c)
        root = find(corners[0])
        for c in corners[1:]:
            parent[find(c)] = root
    return len({find(v) for v in parent})


def main():
    openscad = sys.argv[1] if len(sys.argv) > 1 else "openscad"
    failures = []

    def report(label, ok, got):
        print(f"{'ok  ' if ok else 'FAIL'} {label}: {got}")
        if not ok:
            failures.append(label)

    with tempfile.TemporaryDirectory() as tmp:
        stl = os.path.join(tmp, "case.stl")

        schedules = {}
        for f in (1, 2, 3, 4):
            nums, hubs, chords = echoes(openscad, tmp, f)
            schedules[f] = (nums, hubs, chords)
            want = (10 * f * f + 2, 30 * f * f)
            got = (int(nums["sphere_points"]), int(nums["sphere_struts"]))
            report(f"{f}V sphere has 10F^2+2 vertices and 30F^2 edges", got == want, f"{got[0]} and {got[1]}")

        for f, pub in PUBLISHED.items():
            nums, hubs, chords = schedules[f]
            if "points" in pub:
                got = (int(nums["dome_points"]), int(nums["dome_struts"]))
                report(f"{f}V dome hubs and struts", got == (pub["points"], pub["struts"]), f"{got[0]} hubs, {got[1]} struts")
                report(f"{f}V strut lengths and counts", chords == pub["chords"], chords)
            if "hubs" in pub:
                report(f"{f}V hub types (sockets, count)", hubs == pub["hubs"], hubs)
            if "chord_factors" in pub:
                report(f"{f}V chord factors", [c for c, _ in chords] == pub["chord_factors"], [c for c, _ in chords])

        for f in (2, 3):
            n_hubs = int(schedules[f][0]["dome_points"])
            clashes, misses = [], []
            for i in range(n_hubs):
                thin = run(openscad, FIT, stl, {"frequency": f, "INDEX": i, "GROW": -0.5})
                if "empty" not in thin.stderr.lower() and volume(stl) > 0.01:
                    clashes.append(i)
                thick = run(openscad, FIT, stl, {"frequency": f, "INDEX": i, "GROW": 0.5})
                if "empty" in thick.stderr.lower() or volume(stl) < 1:
                    misses.append(i)
            report(f"{f}V struts thinner than the bore touch none of the {n_hubs} hubs", not clashes,
                   "none touch" if not clashes else f"hubs {clashes} touch")
            report(f"{f}V struts thicker than the bore hit every hub's sockets", not misses,
                   "all hit" if not misses else f"hubs {misses} missed")

        # Every hub type at 2V to 4V is one piece, with octagonal and with
        # round sockets: no part of the body may be cut loose by the bores.
        for f in (2, 3, 4):
            types = int(schedules[f][0]["hub_types"])
            for facets in (8, 64):
                pieces = []
                for t in range(types):
                    result = run(openscad, DOME, stl,
                                 {"frequency": f, "part": '"hub"', "hub_type": t, "outer_facets": facets})
                    pieces.append(solids(stl) if result.returncode == 0 else -1)
                report(f"{f}V, {facets}-sided sockets: each of {types} hub types is one piece",
                       all(p == 1 for p in pieces), f"pieces per type {pieces}")

        # Neighbouring bores keep at least one wall between them, at the
        # computed socket start: bores widened by just under a wall, taken
        # in pairs, never overlap.
        bores = os.path.join(ROOT, "tests", "bores.scad")
        for f in (1, 2, 3, 4):
            types = int(schedules[f][0]["hub_types"])
            touching = []
            for t in range(types):
                result = run(openscad, bores, stl, {"frequency": f, "TYPE": t})
                if "empty" not in result.stderr.lower() and volume(stl) > 0.01:
                    touching.append(t)
            report(f"{f}V bores stay a wall apart in all {types} hub types", not touching,
                   "apart" if not touching else f"types {touching} too close")

    print("all checks passed" if not failures else f"{len(failures)} failed")
    sys.exit(1 if failures else 0)


main()
