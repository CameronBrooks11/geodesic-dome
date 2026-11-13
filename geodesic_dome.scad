//================================================================
//  Geodesic dome hub connectors
//================================================================
// Builds a geodesic dome from an icosahedron, then a pipe hub for every
// vertex with one socket per strut, each pointing along that strut. Hubs and
// struts that are the same are grouped, and the console lists how many of
// each to make.
//
// Grew from the pipe-fitting hubs in
// https://infinityplays.com/3d-part-design-with-openscad-56-making-geodesic-dome-hubs-with-the-pipe-fitting-module/
// (connector_v1 to v3 in this repository's history).

/* [Dome] */
// Subdivisions of each icosahedron edge. Even frequencies give a hemisphere
// with a flat base on the equator.
frequency = 2; // [1:1:6]
// Dome radius to the hub centres (mm)
radius = 1000;

/* [Sockets] */
// Bore that takes the strut (mm)
inner_dia = 20;
// Outside of each socket (mm)
outer_dia = 30;
// Socket depth along the strut (mm)
length = 25;
// Distance from the hub centre to the start of each socket (mm). 0 picks the
// smallest that keeps neighbouring bores apart by at least one wall.
translate_out = 0;
inner_facets = 64;
outer_facets = 8;
// Twist of each socket's outside about its own axis (degrees)
roll_out = 22.5;

/* [Output] */
// "layout": the whole dome with hubs and struts; "hub": one hub type, socket
// axis of the dome pointing up; "none": nothing, for including this file
part = "layout"; // [layout, hub, none]
// Which hub type to render with part = "hub", from the console's list
hub_type = 0;

//──────────────────────── Vector helpers ────────────────────────
EPS = 1e-6;
function unit(v) = v / norm(v);
function same(a, b) = norm(a - b) < EPS;
function index_of(list, p, i = 0) =
  i >= len(list) ? -1 : same(list[i], p) ? i : index_of(list, p, i + 1);
function uniq(list) =
  [for (i = [0:1:len(list) - 1]) if (index_of(list, list[i]) == i) list[i]];

//──────────────────────── Icosahedron, vertex up ────────────────────────
ICO_H = 1 / sqrt(5);
ICO_S = 2 / sqrt(5);
ICO_POINTS = concat(
  [[0, 0, 1]],
  [for (k = [0:4]) [ICO_S * cos(72 * k), ICO_S * sin(72 * k), ICO_H]],
  [for (k = [0:4]) [ICO_S * cos(72 * k + 36), ICO_S * sin(72 * k + 36), -ICO_H]],
  [[0, 0, -1]]
);
ICO_FACES = [
  for (k = [0:4]) [0, 1 + k, 1 + (k + 1) % 5],
  for (k = [0:4]) [1 + k, 6 + k, 1 + (k + 1) % 5],
  for (k = [0:4]) [1 + (k + 1) % 5, 6 + k, 6 + (k + 1) % 5],
  for (k = [0:4]) [11, 6 + (k + 1) % 5, 6 + k],
];

//──────────────────────── Geodesic sphere (class I) ────────────────────────
// A point on face [a, b, c] at grid position (i, j), pushed out to the sphere.
function grid_point(f, i, j, n) =
  let (a = ICO_POINTS[f[0]], b = ICO_POINTS[f[1]], c = ICO_POINTS[f[2]])
  unit(a * (n - i - j) + b * i + c * j);

function sphere_points(n) = uniq([
  for (f = ICO_FACES, i = [0:n], j = [0:n - i]) grid_point(f, i, j, n)
]);

function sphere_edges(n) = [
  for (f = ICO_FACES, i = [0:n - 1], j = [0:n - 1 - i])
    each [
      [grid_point(f, i, j, n), grid_point(f, i + 1, j, n)],
      [grid_point(f, i, j, n), grid_point(f, i, j + 1, n)],
      [grid_point(f, i + 1, j, n), grid_point(f, i, j + 1, n)],
    ]
];

//──────────────────────── Dome ────────────────────────
// The base is the highest ring of vertices at or below the equator, plus any
// rings within 0.05 of the radius below it. Even frequencies have a ring on
// the equator, so their base is flat; odd ones merge two close rings into a
// nearly flat base, as in the usual 3V 5/8 dome.
BASE_MERGE = 0.05;
function base_z(points) =
  let (top = max([for (p = points) if (p.z <= EPS) p.z]))
  min([for (p = points) if (p.z <= top + EPS && p.z >= top - BASE_MERGE) p.z]);

function dome_points(n) =
  let (pts = sphere_points(n), z0 = base_z(pts))
  [for (p = pts) if (p.z >= z0 - EPS) p];

// Each strut once, as a pair of unit vectors.
function dome_edges(n) =
  let (z0 = base_z(sphere_points(n)), all = sphere_edges(n))
  [
    for (i = [0:len(all) - 1])
      let (e = all[i])
      if (e[0].z >= z0 - EPS && e[1].z >= z0 - EPS)
        if (len([for (k = [0:1:i - 1]) if ((same(all[k][0], e[0]) && same(all[k][1], e[1])) || (same(all[k][0], e[1]) && same(all[k][1], e[0]))) 1]) == 0)
          e
  ];

function neighbours(v, edges) =
  [for (e = edges) if (same(e[0], v)) e[1] else if (same(e[1], v)) e[0]];

//──────────────────────── Hubs ────────────────────────
// Strut directions at vertex v in the hub's own frame: z out along v, x
// toward the first strut.
function hub_dirs(v, edges) =
  let (
    ns = neighbours(v, edges),
    ds = [for (p = ns) unit(p - v)],
    x0 = unit(ds[0] - (ds[0] * v) * v),
    y0 = cross(v, x0)
  )
  [for (d = ds) [d * x0, d * y0, d * v]];

function round_to(x, step) = round(x / step) * step;
function sorted(v) =
  len(v) <= 1 ? v
  : let (p = v[0], rest = [for (i = [1:len(v) - 1]) v[i]])
    concat(sorted([for (x = rest) if (x < p) x]), [p], sorted([for (x = rest) if (x >= p) x]));

// A hub's shape, up to rotation about its axis and mirroring: the number of
// struts, their elevations, and the angles between neighbouring struts.
function hub_signature(dirs) =
  let (
    az = sorted([for (d = dirs) (atan2(d.y, d.x) + 360) % 360]),
    gaps = [for (i = [0:len(az) - 1]) (i < len(az) - 1 ? az[i + 1] : az[0] + 360) - az[i]]
  )
  [len(dirs), sorted([for (d = dirs) round_to(asin(d.z), 0.1)]), sorted([for (g = gaps) round_to(g, 0.1)])];

// [[signature, representative vertex, count], ...]
function hub_types(points, edges) =
  let (
    sigs = [for (p = points) hub_signature(hub_dirs(p, edges))],
    first = [for (i = [0:len(sigs) - 1]) if (len([for (k = [0:1:i - 1]) if (sigs[k] == sigs[i]) 1]) == 0) i]
  )
  [for (i = first) [sigs[i], points[i], len([for (s = sigs) if (s == sigs[i]) 1])]];

// [[chord factor, count], ...], shortest first; chord factor x radius is the
// centre-to-centre strut length.
function strut_types(edges) =
  let (
    cf = [for (e = edges) round_to(norm(e[0] - e[1]), 0.00001)],
    kinds = sorted(uniq([for (c = cf) [c, 0, 0]]) * [1, 0, 0])
  )
  [for (c = kinds) [c, len([for (x = cf) if (abs(x - c) < 0.000005) 1])]];

// The smallest angle between two struts at any hub.
function min_strut_angle(points, edges) =
  min([for (p = points) let (ds = hub_dirs(p, edges)) for (i = [0:len(ds) - 2], j = [i + 1:len(ds) - 1]) acos(min(1, ds[i] * ds[j]))]);

// Where sockets start: far enough out that neighbouring bores, at the
// tightest angle, stay one wall apart.
function socket_start(points, edges) =
  translate_out > 0 ? translate_out
  : let (wall = (outer_dia - inner_dia) / 2)
    (inner_dia / 2 + wall / 2) / sin(min_strut_angle(points, edges) / 2);

//──────────────────────── Geometry ────────────────────────
// Rotate +z onto direction d.
module along(d) {
  rotate([0, acos(d.z / norm(d)), atan2(d.y, d.x)]) children();
}

// The body is the hull of the sockets' bases. Each socket's outside runs from
// the centre, so it joins the body along its whole length: when sockets
// started at the body's surface instead, the bores cut slivers of the hull
// loose between neighbouring sockets.
module hub(dirs, start) {
  difference() {
    union() {
      hull() for (d = dirs) along(d) rotate([0, 0, roll_out]) cylinder(d = outer_dia, h = start, $fn = outer_facets);
      for (d = dirs) along(d) rotate([0, 0, roll_out]) cylinder(d = outer_dia, h = start + length, $fn = outer_facets);
    }
    for (d = dirs) along(d) translate([0, 0, start]) cylinder(d = inner_dia, h = length + 1, $fn = inner_facets);
  }
}

// Every strut at its cut length: from the start of one hub's socket to the
// start of the other's.
module struts(edges, dia, start) {
  for (e = edges) {
    a = radius * e[0]; b = radius * e[1];
    translate(a) along(b - a) translate([0, 0, start]) cylinder(d = dia, h = norm(b - a) - 2 * start, $fn = 24);
  }
}

// Place a hub at vertex v, rotated from its own frame to the dome's.
module at_vertex(v, edges) {
  ns = neighbours(v, edges);
  d0 = unit(ns[0] - v);
  x0 = unit(d0 - (d0 * v) * v);
  y0 = cross(v, x0);
  multmatrix([
    [x0.x, y0.x, v.x, radius * v.x],
    [x0.y, y0.y, v.y, radius * v.y],
    [x0.z, y0.z, v.z, radius * v.z],
    [0, 0, 0, 1],
  ]) children();
}

//──────────────────────── Schedule and render ────────────────────────
POINTS = dome_points(frequency);
EDGES = dome_edges(frequency);
START = socket_start(POINTS, EDGES);
HUBS = hub_types(POINTS, EDGES);
STRUTS = strut_types(EDGES);

if (part != "none") {
  echo(str("Dome: ", frequency, "V, radius ", radius, " mm, ", len(POINTS), " hubs, ", len(EDGES), " struts"));
  echo(str("Sockets start ", round_to(START, 0.01), " mm from each hub centre"));
  for (i = [0:len(HUBS) - 1])
    echo(str("Hub type ", i, ": ", HUBS[i][2], " needed, ", HUBS[i][0][0], " sockets, elevations ", HUBS[i][0][1], " deg"));
  for (s = STRUTS)
    echo(str("Strut: ", s[1], " needed, chord factor ", s[0], ", centre to centre ", round_to(s[0] * radius, 0.1),
             " mm, cut length ", round_to(s[0] * radius - 2 * START, 0.1), " mm"));
}

if (part == "hub") {
  assert(hub_type >= 0 && hub_type < len(HUBS), str("hub_type must be 0 to ", len(HUBS) - 1));
  hub(hub_dirs(HUBS[hub_type][1], EDGES), START);
} else if (part == "layout") {
  struts(EDGES, inner_dia, START);
  for (p = POINTS) at_vertex(p, EDGES) hub(hub_dirs(p, EDGES), START);
} else if (part != "none") {
  assert(false, str("part must be layout, hub or none, not ", part));
}
