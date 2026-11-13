// Hub INDEX, placed on the dome, intersected with every strut at its cut
// length and diameter inner_dia + GROW. With GROW < 0 the struts sit inside
// the bores and nothing should overlap; with GROW > 0 they are wider than the
// bores and should overlap each of this hub's sockets. The struts start
// 0.3 mm past the bottom of each socket, so the check doesn't measure two
// faces lying on the same plane.
include <../geodesic_dome.scad>;

part = "none";
GROW = -0.5;
INDEX = 0;

intersection() {
  at_vertex(POINTS[INDEX], EDGES) hub(hub_dirs(POINTS[INDEX], EDGES), START);
  struts(EDGES, inner_dia + GROW, START + 0.3);
}
