//================================================================
//  Geodesic‐Dome Pipe Connector Library (with default $fn)
//================================================================
// Modified from: https://infinityplays.com/3d-part-design-with-openscad-56-making-geodesic-dome-hubs-with-the-pipe-fitting-module/

//──────────────────────── Configuration ────────────────────────
show_fitting = true;
inner_facets = 64; // default $fn for all branches
outer_facets = 8; // default $fn for all branches

rotZ_out = 0; // rotation around Z axis for the outer cylinder
rotZ_in = 0; // rotation around Z axis for the inner cylinder
inner_dia = 20; // inner diameter of the pipe
outer_dia = 30; // outer diameter of the pipe
length = 50; // length of the pipe
num = 6; // number of facets for the pipe
translate_out = 12; // translation out from center point
tilt = 100;
roll_out = 45/2;
roll_in = 0;

outer_rad = outer_dia / 2;


// branch list entries can now be either
//  > 6‑element arrays: [ 0:on?, 1:[tilt,azimuth,roll_in,roll_out], 2:outØ, 3:inØ, 4:len, 5: translate_out ]
branches = [
  [true, [tilt, 0, roll_in, roll_out], outer_dia, inner_dia, length, translate_out],
  [true, [tilt, 60, roll_in, roll_out], outer_dia, inner_dia, length, translate_out],
  [true, [tilt, 120, roll_in, roll_out], outer_dia, inner_dia, length, translate_out],
  [true, [tilt, 180, roll_in, roll_out], outer_dia, inner_dia, length, translate_out],
  [true, [tilt, 240, roll_in, roll_out], outer_dia, inner_dia, length, translate_out],
  [true, [tilt, 300, roll_in, roll_out], outer_dia, inner_dia, length, translate_out]
];

//──────────────────────── Module Definitions ────────────────────
// draw the central sphere
module fitting_center() {
  rotate_extrude(angle = 360) 
  rotate([0, 0, -tilt+90])
  translate([translate_out + outer_dia/2, 0])
    square([outer_dia, outer_dia], center=true);
}

// drill the bores (inside) for every branch
module fitting_inside(branch_list) {
  for (i = [0:len(branch_list) - 1]) {
    b = branch_list[i];
    if (b[0]) {
      rotate([0, 0, b[1][1]])
        rotate([b[1][0], 0, 0])
          rotate([0, 0, b[1][2]])
            translate([0, 0, b[5]-translate_out/2])
              cylinder(
                h=b[4] + translate_out,
                r=b[3] / 2,
                center=false,
                $fn=inner_facets
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
            translate([0, 0, b[5]])
              cylinder(
                h=b[4],
                r=b[2] / 2,
                center=false,
                $fn=outer_facets
              );
    }
  }
}

// compose the full fitting
module fitting(branch_p) {
  union(){
    difference() {
      fitting_center();
      fitting_inside(branch_p);
    }
    difference() {
      fitting_outside(branch_p);
      fitting_inside(branch_p);
    }
  }
}

//──────────────────────── Render ───────────────────────────────
if (show_fitting)
  fitting(branches);