//================================================================
//  Geodesic‐Dome Pipe Connector Library (with default $fn)
//================================================================
// Modified from: https://infinityplays.com/3d-part-design-with-openscad-56-making-geodesic-dome-hubs-with-the-pipe-fitting-module/

//──────────────────────── Configuration ────────────────────────
show_fitting = true;
default_facet = 64; // default $fn for all branches

// center sphere params: [ diameter, facets,   rotation_vec,    scale_vec ]
center_params = [
  12, // diameter
  6, // $fn
  [0, 0, 0], // rotate([X,Y,Z])
  [1, 1, 0.25], // scale([X,Y,Z])
];

// global “tilt” applied to every branch: rotate([X,Y,Z])
rotate_all = [0, 0, 0];

// branch list entries can now be either
//  > 7‑element arrays: [ 0:on?, 1:[angX,angY,angZ], 2:rotZ_out, 3:rotZ_in, 4:outØ, 5:inØ, 6:len ]
//  > 9‑element arrays: [ 0:on?, 1:[angX,angY,angZ], 2:rotZ_out, 3:rotZ_in, 4:outØ, 5:inØ, 6:len, 7:$fn_out, 8:$fn_in ]

branches = [
  [true, [96, 0, 150], 0, 0, 6, 4, 12, 16, 16],
  [true, [96, 0, 30], 0, 0, 6, 4, 12, 256, 256],
  [true, [264, 0, 30], 0, 0, 6, 4, 12, 8, 8],
  [true, [180, 84, 60], 0, 0, 6, 4, 12],
  [true, [0, 96, 0], 0, 0, 6, 4, 12],
  [true, [0, 264, 0], 0, 0, 6, 4, 12],
];

//──────────────────────── Helpers ─────────────────────────────
// safely grab branch[idx] or default to default_facet
function branch_fn(b, idx) = len(b) > idx ? b[idx] : default_facet;

//──────────────────────── Module Definitions ────────────────────
// draw the central sphere
module fitting_center(dia, fn, rot_vec, scale_vec) {
  rotate(rot_vec)
    scale(scale_vec)
      sphere(dia, $fn=fn);
}

// drill the bores (inside) for every branch
module fitting_inside(branch_list, rot_all_vec) {
  for (i = [0:len(branch_list) - 1]) {
    b = branch_list[i];
    if (b[0]) {
      rotate(rot_all_vec)
        rotate(b[1])
          rotate([0, 0, b[3]])
            cylinder(
              h=b[6] + 1,
              r=b[5] / 2,
              center=false,
              $fn=branch_fn(b, 8)
            );
    }
  }
}

// add the stub‐cylinders (outside) for every branch
module fitting_outside(branch_list, rot_all_vec) {
  for (i = [0:len(branch_list) - 1]) {
    b = branch_list[i];
    if (b[0]) {
      rotate(rot_all_vec)
        rotate(b[1])
          rotate([0, 0, b[2]])
            cylinder(
              h=b[6],
              r=b[4] / 2,
              center=false,
              $fn=branch_fn(b, 7)
            );
    }
  }
}

// compose the full fitting
module fitting(center_p, branch_p, rot_all_p) {
  difference() {
    fitting_center(
      center_p[0], // diameter
      center_p[1], // $fn
      center_p[2], // rot_vec
      center_p[3] // scale_vec
    );
    fitting_inside(branch_p, rot_all_p);
  }
  difference() {
    fitting_outside(branch_p, rot_all_p);
    fitting_inside(branch_p, rot_all_p);
  }
}

//──────────────────────── Render ───────────────────────────────
if (show_fitting)
  fitting(center_params, branches, rotate_all);
