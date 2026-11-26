#!/bin/sh
# Export every printed part to stl/ (needs OpenSCAD on the PATH).
cd "$(dirname "$0")"
mkdir -p stl
for p in base_shell base_lid front_panel crank_arm_cap crank_arm_drive yoke_beam pulley_60T \
         rail_L1 rail lifter_L1_cap lifter_L1_drive lifter \
         deck_frame end_plate_drive end_plate_cap stop_bar_drive stop_bar_centre \
         drive_collar end_collar roller_core double_pulley motor_bracket belt_guard \
         lid_frame fit_test; do
  echo "== $p"
  openscad -q -D "part=\"$p\"" -o "stl/$p.stl" paint_roller.scad
done
