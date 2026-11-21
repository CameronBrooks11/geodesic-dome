// A hub for a 3V 5/8 dome of 1.5 m radius, for 1/2" PVC pipe
include <../geodesic_dome.scad>

frequency = 3;
radius = 1500;
// 1/2" schedule 40 PVC is 21.3 mm outside; this leaves 0.5 mm of clearance
inner_dia = 21.8;
outer_dia = 30;
part = "hub";
// The commonest 3V hub: 30 needed, 6 sockets
hub_type = 1;
