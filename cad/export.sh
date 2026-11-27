#!/bin/sh
# Export every printed part to stl/ (needs OpenSCAD on the PATH).
cd "$(dirname "$0")"
mkdir -p stl
# Each part gets the 0.4 mm bed relief from bed_chamfer() in paint_roller.scad.
for p in base_shell base_lid crank_arm_cap crank_arm_drive pulley_60T \
         yoke_lifter_cap yoke_lifter_drive rail_L1 rail lifter \
         deck stop_bar_drive stop_bar_centre roller_drive roller_cap \
         double_pulley motor_bracket belt_guard lid_frame fit_test; do
  echo "== $p"
  openscad -q -D "part=\"$p\"" -o "stl/$p.stl" paint_roller.scad
done
