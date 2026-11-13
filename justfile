default:
    @just --list

# Check the dome's geometry and schedule, socket fit, hub pieces and bore spacing
test:
    python3 tests/test_dome.py

# Print the build schedule for a dome: just schedule 3 1500
schedule frequency="2" radius="1000":
    @openscad -D frequency={{frequency}} -D radius={{radius}} -D 'part="hub"' --export-format echo -o /dev/stdout geodesic_dome.scad 2>/dev/null | sed 's/^ECHO: //; s/^"//; s/"$//'

# Render the README pictures into assets/
images:
    @mkdir -p assets
    montage -version >/dev/null
    openscad --render --colorscheme=Tomorrow --imgsize=700,450 --viewall --autocenter --camera=0,0,0,70,0,25,5200 -D frequency=2 -D 'part="layout"' -o assets/layout-2v.png geodesic_dome.scad
    for t in 0 1 2; do openscad --render --colorscheme=Tomorrow --imgsize=300,300 --viewall --autocenter --camera=0,0,0,35,0,20,260 -D frequency=2 -D 'part="hub"' -D hub_type=$t -o assets/hub-2v-$t.png geodesic_dome.scad; done
    montage -label 'type 0: 5 sockets' assets/hub-2v-0.png -label 'type 1: 6 sockets' assets/hub-2v-1.png -label 'type 2: 4 sockets (base)' assets/hub-2v-2.png -tile 3x1 -geometry +4+4 assets/hubs-2v.png
    rm assets/hub-2v-0.png assets/hub-2v-1.png assets/hub-2v-2.png
