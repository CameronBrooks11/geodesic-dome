// Echoes the numbers tests/test_dome.py checks, for the frequency given with -D.
include <../geodesic_dome.scad>;

part = "none";

echo(sphere_points = len(sphere_points(frequency)), sphere_struts = len(uniq_edges(sphere_edges(frequency))));
echo(dome_points = len(POINTS), dome_struts = len(EDGES), hub_types = len(HUBS), start = START);
echo(hubs = [for (h = HUBS) [h[0][0], h[2]]]);
echo(struts = STRUTS);

function uniq_edges(all) = [
  for (i = [0:len(all) - 1])
    let (e = all[i])
    if (len([for (k = [0:1:i - 1]) if ((same(all[k][0], e[0]) && same(all[k][1], e[1])) || (same(all[k][0], e[1]) && same(all[k][1], e[0]))) 1]) == 0)
      e
];
