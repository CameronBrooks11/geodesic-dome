//================================================================
//  Geodesic‐Dome Pipe Connector Library (with default $fn)
//================================================================
// Modified from: https://infinityplays.com/3d-part-design-with-openscad-56-making-geodesic-dome-hubs-with-the-pipe-fitting-module/

//──────────────────────── Configuration ────────────────────────
show_fitting = true;
default_facet_in = 64; // default $fn for all branches
default_facet_out = 8; // default $fn for all branches

rotZ_out = 0; // rotation around Z axis for the outer cylinder
rotZ_in = 0; // rotation around Z axis for the inner cylinder
inner_dia = 5; // inner diameter of the pipe
outer_dia = 8; // outer diameter of the pipe
length = 16; // length of the pipe
num = 6; // number of facets for the pipe

outer_rad = outer_dia / 2;

diff = (outer_rad * (1 - cos(180 / num)));
diff_multi = 1 + diff * 2 / outer_rad;
echo("diff: ", diff);
echo("diff_multi: ", diff_multi);

scale = ( (outer_rad * diff_multi) / length);

// center sphere params: [ diameter, facets,   rotation_vec,    scale_vec ]
center_params = [
  length, // diameter
  num, // $fn aka number pipes
  [0, 0, 30], // rotate([X,Y,Z])
  [1, 1, scale], // scale([X,Y,Z])
];

// branch list entries can now be either
//  > 5‑element arrays: [ 0:on?, 1:[tilt,azimuth,roll], 2:outØ, 3:inØ, 4:len ]
//  > 7‑element arrays: [ 0:on?, 1:[tilt,azimuth,roll], 2:outØ, 3:inØ, 4:len, 5:out_fn, 6:in_fn ]
branches = [
  [true, [95, 0, 0, 0], outer_dia, inner_dia, length],
  [true, [95, 60, 0, 0], outer_dia, inner_dia, length],
  [true, [95, 120, 0, 0], outer_dia, inner_dia, length],
  [true, [95, 180, 0, 0], outer_dia, inner_dia, length],
  [true, [95, 240, 0, 0], outer_dia, inner_dia, length],
  [true, [95, 300, 0, 0], outer_dia, inner_dia, length]
];

//──────────────────────── Helpers ─────────────────────────────
// safely grab branch[idx] or default to default_facet
function branch_fn_in(b, idx) = len(b) > idx ? b[idx] : default_facet_in;
function branch_fn_out(b, idx) = len(b) > idx ? b[idx] : default_facet_out;

//──────────────────────── Module Definitions ────────────────────
// draw the central sphere
module fitting_center(dia, fn, rot_vec, scale_vec) {
  rotate(rot_vec)
    scale(scale_vec)
      sphere(dia, $fn=fn);
}

// drill the bores (inside) for every branch
module fitting_inside(branch_list) {
  for (i = [0:len(branch_list) - 1]) {
    b = branch_list[i];
    if (b[0]) {
      rotate([0, 0, b[1][1]])
        rotate([b[1][0], 0, 0])
          rotate([0, 0, b[1][2]])
            translate([0, 0, -0.5])
              cylinder(
                h=b[4] + 1,
                r=b[3] / 2,
                center=false,
                $fn=branch_fn_in(b, 8)
              );
    }
  }
}

// add the stub‐cylinders (outside) for every branch
module fitting_outside(branch_list) {
  for (i = [0:len(branch_list) - 1]) {
    b = branch_list[i];
    if (b[0]) {
      rotate([0, 0, b[1][1]])
        rotate([b[1][0], 0, 0])
          rotate([0, 0, b[1][3]])
            cylinder(
              h=b[4],
              r=b[2] / 2,
              center=false,
              $fn=branch_fn_out(b, 7)
            );
    }
  }
}

// compose the full fitting
module fitting(center_p, branch_p) {
  difference() {
    fitting_center(
      center_p[0], // diameter
      center_p[1], // $fn
      center_p[2], // rot_vec
      center_p[3] // scale_vec
    );
    fitting_inside(branch_p);
  }
  difference() {
    fitting_outside(branch_p);
    fitting_inside(branch_p);
  }
}

//──────────────────────── Render ───────────────────────────────
if (show_fitting)
  fitting(center_params, branches);
