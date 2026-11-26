// Assembly view of the paint roller stack (for checking fits, not for printing).
include <paint_roller.scad>
part = "none";
levels = 3;        // 1..3
phi = 90;          // crank angle: 90 = cap end at the top of its stroke
show_bottles = true;

function hS(s) = s*bias + s*crank_r*sin(phi);            // pin offset at each end
function pinz(n) = pin1 + pitch*(n-1);
theta = atan((hS(1) - hS(-1)) / (2*lift_x));

module deck_place(n)
    translate([-lift_x, 0, pinz(n) + hS(-1)]) rotate([0, -theta, 0]) translate([lift_x, 0, -pin_dz]) children();

module level(n) deck_place(n) {
    color("SteelBlue") deck_frame();
    color("SkyBlue") { end_plate(-1); end_plate(1); stop_bar(drive_bar_x, false); stop_bar(centre_bar_x, true); }
    color("Orange") roller_parts();
    color("DimGray") for (y = roller_ys) xcyl(y == roller_ys[1] ? -150 : -120, 120, y, roller_z, 5, 16);
    color("Gainsboro", 0.6) for (y = roller_ys) xcyl(core_x0, core_x1, y, roller_z, roller_d, 24);
    if (n < levels) color("LightSteelBlue") belt_guard();
    if (n == 1) {
        color("SkyBlue") motor_bracket();
        color("Black") box(motor_face_x-40, motor_face_x, motor_y-21, motor_y+21, roller_z-21, roller_z+21);
    }
    if (show_bottles) color("Crimson", 0.8) for (y = valley_ys) {
        xcyl(drive_bar_x + bar_w/2 + dome_h + 1, drive_bar_x + bar_w/2 + dome_h + 1 + bottle_l, y, bottle_z, bottle_d, 32);
        xcyl(cap_stop_x - 1 - bottle_l, cap_stop_x - 1, y, bottle_z, bottle_d, 32);
    }
}

module lifters() for (s = [-1,1]) for (sy = [-1,1]) {
    pl = (sy > 0) ? [0,0,0] : [0,0,180];
    color("Goldenrod") {
        translate([s*lift_x, sy*lift_y, beam_top + s*crank_r*sin(phi)]) rotate(pl) lifter_L1(s);
        for (n = [2:levels]) if (levels >= 2)
            translate([s*lift_x, sy*lift_y, pinz(n) + hS(s) - seg_pin]) rotate(pl) lifter_std();
    }
}

module rails() for (mx = [0,1], my = [0,1]) mirror([mx,0,0]) mirror([0,my,0]) color("Silver") {
    rail_seg(rail_L1, base_h);
    for (n = [2:levels]) if (levels >= 2) rail_seg(pitch, base_h + rail_L1 + pitch*(n-2));
}

color("DarkSlateGray") base_shell();
color("SlateGray") base_lid();
color("DimGray") front_panel();
color("Orange") { crank_arm(1, phi); crank_arm(-1, phi+180); pulley60(); }
color("Tomato") { yoke_beam(1, crank_r*sin(phi)); yoke_beam(-1, -crank_r*sin(phi)); }
color("DimGray") xcyl(-101, 101, 0, crank_z, 5, 16);
color("Black") box(-50, -10, rock_motor[0]-21, rock_motor[0]+21, rock_motor[1]-21, rock_motor[1]+21);
rails();
lifters();
for (n = [1:levels]) level(n);
color("SlateGray") lid_frame(base_h + rail_L1 + pitch*(levels-1));
