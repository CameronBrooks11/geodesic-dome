//================================================================
//  Geodesic‐Dome Pipe Connector Library v3
//================================================================

//──────────────────────── Configuration ────────────────────────
show_fitting   = true;

// pipe geometry
inner_dia      = 20;  // inner bore diameter
outer_dia      = 30;  // outer stub diameter
length         = 10;  // pipe stub length protruding from center

translate_out  = 12;  // how far stub sticks out from center

// faceting
inner_facets   = 64;  // default $fn for all inner bores
outer_facets   = 8;   // default $fn for all outer stubs

// branch layout
num            = 8;               // how many branches
tilt           = 100;             // elevation tilt (degrees)
roll_in        = 0;               // twist of inner bore
roll_out       = 45/2;            // twist of outer stub

//──────────────────────── Branch‑generator Function ────────────────────────
// returns a list of 6‑element arrays: [ 0:on?, 1:[tilt,azimuth,roll_in,roll_out], 2:outØ, 3:inØ, 4:len, 5: translate_out ]
function make_branches(n, tilt, rin, rout, od, id, leng, tout) =
  [ for (i = [0 : n-1])
      [ true,
        [ tilt, i*360/n, rin, rout ],
        od, id, leng+od, tout
      ]
  ];

// now generate your branches once:
branches = make_branches(
  num,
  tilt, roll_in, roll_out,
  outer_dia, inner_dia,
  length,
  translate_out
);

//──────────────────────── Module Definitions ────────────────────

// central “hub” profile, revolve & carve
module fitting_center() {
  face_offset = 360/(2*num);
  rotate([0, 0, face_offset])
  rotate_extrude(angle = 360, $fn = num)
    rotate([0, 0, -tilt + 90])
      translate([ translate_out + outer_dia/2, 0 ])
        square([ outer_dia, outer_dia ], center = true);
}

// drill bores in every branch
module fitting_inside(branch_list) {
  for (b = branch_list)
    if (b[0]) {
      rotate([ 0, 0, b[1][1] ])
        rotate([ b[1][0], 0, 0 ])
          rotate([ 0, 0, b[1][2] ])
            translate([ 0, 0, b[5] - translate_out/2 ])
              cylinder(
                h      = b[4] + translate_out,
                r      = b[3]/2,
                center = false,
                $fn    = inner_facets
              );
    }
}

// add outer pipe stubs
module fitting_outside(branch_list) {
  for (b = branch_list)
    if (b[0]) {
      rotate([ 0, 0, b[1][1] ])
        rotate([ b[1][0], 0, 0 ])
          rotate([ 0, 0, b[1][3] ])
            translate([ 0, 0, b[5] ])
              cylinder(
                h      = b[4],
                r      = b[2]/2,
                center = false,
                $fn    = outer_facets
              );
    }
}

// assemble the full connector
module fitting(branch_list) {
  union() {
    difference() {
      fitting_center();
      fitting_inside(branch_list);
    }
    difference() {
      fitting_outside(branch_list);
      fitting_inside(branch_list);
    }
  }
}

//──────────────────────── Render ───────────────────────────────
if (show_fitting)
  fitting(branches);
