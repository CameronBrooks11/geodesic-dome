// Every pair of bores in hub type TYPE, each widened by just under one wall
// ((outer_dia - inner_dia) / 2), intersected pairwise. If neighbouring bores
// keep at least one wall between them, nothing is left.
include <../geodesic_dome.scad>;

part = "none";
TYPE = 0;
WALL = (outer_dia - inner_dia) / 2;

D = hub_dirs(HUBS[TYPE][1], EDGES);
module bore(d) along(d) translate([0, 0, START]) cylinder(d = inner_dia + WALL - 0.2, h = length + 1, $fn = inner_facets);

for (i = [0:len(D) - 2], j = [i + 1:len(D) - 1])
  intersection() { bore(D[i]); bore(D[j]); }
