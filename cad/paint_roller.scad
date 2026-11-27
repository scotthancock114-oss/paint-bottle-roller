// Paint Bottle Roller v1 - printed parts (parametric OpenSCAD)
//
// Designed for FDM: thick solid sections (structural walls 6-8 mm), wide flat
// faces on the bed, gussets at corners, no thin tabs or tongues, no supports.
//
// Revision 3 merges parts to suit a 256 x 256 x 256 mm bed (Bambu X1C): the
// end plates are part of the deck, the collars are part of the roller cores,
// the level 1 lifters are part of the yoke beams, and the front panel is part
// of the base shell.
//
// Every printed part is modelled in its assembled position in one global
// frame, and print_part() turns it onto the print bed.
//   X = bottle axis (caps toward +X, drive end at -X)
//   Y = depth (front = -Y, back wall = +Y)
//   Z = up, z = 0 is the table under the base
//
// Export one part:   openscad -D 'part="deck_frame"' -o deck_frame.stl paint_roller.scad
// Export all parts:  ./export.sh
// Assembly view:     open assembly.scad
//
// Hardware assumed: 5 mm shafts, 625ZZ bearings (MR105ZZ: set bearing="MR105"),
// M3 / M4 / M5 screws, GT2 6 mm belts, NEMA 17 motors.

part = "deck";   // see the list at the bottom of the file

/* [Fit - tune these with fit_test.stl first] */
bearing   = "625";      // "625" (5x16x5) or "MR105" (5x10x4)
fit_brg   = 0.0;        // added to the bearing OD for press-fit seats
fit_hole  = 0.2;        // clearance on 5 mm shaft holes
fit_slide = 0.3;        // gap each side between lifter bar and guard rail
m3_tap    = 2.6;        // hole for M3 screws threading into plastic
m3_clr    = 3.4;
m4_clr    = 4.4;
m5_clr    = 5.3;

/* [Bottle] */
bottle_d = 26;
bottle_l = 92;

$fn = 64;

// ---------------------------------------------------------------- derived
brg_od = bearing == "625" ? 16 : 10;
brg_w  = bearing == "625" ? 5 : 4;
seat_d = brg_od + fit_brg;
bore   = 5 + fit_hole;

// Base
base_l = 250;  base_w = 160;  base_h = 62;      // fits a 256 mm bed
lid_t  = 6;    shell_h = base_h - lid_t;
wall   = 4;    floor_t = 3;
hb = base_l/2; wb = base_w/2;

// Rocking crank (one 5 mm shaft along X, two cranks 180 deg apart)
crank_r = 19;           // +/-19 mm at each deck end
crank_z = 35;
tower_x = 84;           // crankshaft bearing towers at X = +/-84 (8 thick)
beam_h  = 24.5;         // Scotch-yoke beam height
slot_h  = brg_od + 0.5; // yoke slot for the crank-pin bearing
bias_deg = 3;           // caps-up bias at mid stroke

// Stack
lift_x  = 110;          // lifter / rail centre X
lift_y  = 58;           // lifter inner face |Y|
lifter_w = 14;  lifter_t = 12;
rock_clear = 32;        // base top to level-1 deck underside at mid stroke
pitch   = 90;           // level spacing
seg_pin = 66;           // pin height inside a standard lifter segment
lap     = 20;           // lifter lap-joint length

bias     = lift_x * tan(bias_deg);   // 5.76: +X lifters longer, -X shorter
deck_z1  = base_h + rock_clear;      // 94
pin_dz   = 32;                       // deck pin height above deck underside
pin1     = deck_z1 + pin_dz;         // 126
beam_top = crank_z + beam_h/2;
L1_len   = pin1 + (90 - seg_pin) - beam_top;   // 102.75 nominal
rail_L1  = deck_z1 + 72 - base_h;              // 104

// Guard-rail profile: a thick U channel (7 mm flanges, 8 mm back)
back_y0 = lift_y + lifter_t + fit_slide;   // 70.3
back_y1 = back_y0 + 8;                     // 78.3
fl_in   = lifter_w/2 + fit_slide;          // 7.3
fl_out  = fl_in + 7;                       // 14.3
tongue  = 10;                              // stacking tongue height
bolt_y  = (back_y0 + back_y1) / 2;         // cross-bolt line

// Deck (one level)
hx = 122;  hy = 57.5;          // deck 244 x 115
deck_floor = 3;
roller_z  = 14;                // roller centres above deck underside
roller_d  = 16;                // 12 mm core + silicone sleeve
roller_ys = [-43.5, -14.5, 14.5, 43.5];   // roller 2 (driven) = -14.5
end_t     = 8;   x_in = hx - end_t;        // end plates |X| 114..122
plate_top = 39;
boss_x0 = 105;  boss_y0 = 49;  boss_z0 = 24;   // pin bosses
back_top = 42;  lip_h = 10;
bottle_z = roller_z + sqrt(pow((bottle_d + roller_d)/2, 2) - pow(29/2, 2)); // 29.2
bar_w = 8;  bar_z0 = 24;  bar_z1 = 36;  dome_h = 1.5;  dome_r = 4;
valley_ys = [-29, 0, 29];
drive_bar_x = -91.5;
cap_stop_x  = x_in - dome_h;                       // 112.5
centre_bar_x = (drive_bar_x + bar_w/2 + dome_h + cap_stop_x) / 2;   // 13.25
collar_x0 = -x_in + 0.5;                           // -113.5
core_x0 = -94;  core_x1 = 104;
pulley_x0 = -hx - 2.5;                             // double pulley starts here
motor_y  = roller_ys[1] + 59;                      // GT2 158 loop, 20T:20T
motor_face_x = -155;

// ------------------------------------------------------------------ helpers
module box(x0, x1, y0, y1, z0, z1)
    translate([min(x0,x1), min(y0,y1), min(z0,z1)])
        cube([abs(x1-x0), abs(y1-y0), abs(z1-z0)]);

module rbox(x0, x1, y0, y1, z0, z1, r)
    hull() for (x = [x0+r, x1-r], y = [y0+r, y1-r])
        translate([x, y, z0]) cylinder(r=r, h=z1-z0);

module xcyl(x0, x1, y, z, d, fn=64)           // cylinder along X
    translate([min(x0,x1), y, z]) rotate([0,90,0]) cylinder(d=d, h=abs(x1-x0), $fn=fn);

module ycyl(x, y0, y1, z, d, fn=64)           // cylinder along Y
    translate([x, min(y0,y1), z]) rotate([-90,0,0]) cylinder(d=d, h=abs(y1-y0), $fn=fn);

module zcyl(x, y, z0, z1, d, fn=64)
    translate([x, y, min(z0,z1)]) cylinder(d=d, h=abs(z1-z0), $fn=fn);

module hexagon(af, h) cylinder(d=af/cos(30), h=h, $fn=6);

// Domed bumper on a face at x = xf pointing in direction dir (+1/-1)
module dome(xf, y, z, dir)
    intersection() {
        translate([xf - dir*(dome_r - dome_h), y, z]) sphere(r=dome_r, $fn=32);
        box(xf, xf + dir*(dome_h + 0.01), y-dome_r, y+dome_r, z-dome_r, z+dome_r);
    }

// GT2 2 mm tooth gap (from the widely used parametric pulley profile)
gt2_pts = [[0.747183,-0.5],[0.747183,0],[0.647876,0.037218],[0.598311,0.130528],
  [0.578556,0.238423],[0.547158,0.343077],[0.504649,0.443762],[0.451556,0.53975],
  [0.358229,0.636924],[0.2484,0.707276],[0.127259,0.750044],[0,0.76447],
  [-0.127259,0.750044],[-0.2484,0.707276],[-0.358229,0.636924],[-0.451556,0.53975],
  [-0.504649,0.443762],[-0.547158,0.343077],[-0.578556,0.238423],[-0.598311,0.130528],
  [-0.648009,0.037218],[-0.747183,0],[-0.747183,-0.5]];

module gt2_ring(teeth, h) {    // toothed section, axis Z, z 0..h
    od = teeth * 2 / PI - 0.508;
    difference() {
        cylinder(d=od, h=h, $fn=teeth*4);
        for (i = [0:teeth-1]) rotate([0,0,i*360/teeth])
            translate([0, -od/2, -1]) linear_extrude(h+2) polygon(gt2_pts);
    }
}

// Radial M3 grub screw with nut slot, in a hub along Z (local coords)
module grub_m3(zc, hub_r, from_z) {
    translate([0, 0, zc]) rotate([0,90,0]) cylinder(d=3.1, h=hub_r+1, $fn=24);
    // nut slot, open toward the hub end face at from_z
    box(3.3, 5.9, -2.9, 2.9, from_z < zc ? from_z - 1 : zc - 2.9,
                             from_z < zc ? zc + 2.9 : from_z + 1);
}

// =================================================================== BASE
lid_screws = [[121,50],[121,-50],[-121,50],[-121,-50],[-60,-72],[0,72]];
pcb = [-55, 35, -72, -2];              // 90 x 70 perfboard footprint
usb_x = -30;                           // USB slot in the front wall
jack_x = 60;                           // DC jack in the back wall
rock_motor = [35.5, 26];               // rock motor centre (Y, Z), face at X = -50
rock_u = [35.5, -9] / norm([35.5, -9]);// belt tension direction
mplate = [-56, -50];                   // rock motor plate X range (6 mm)

// Right-angle gusset: triangle in the plane spanned by X and Z, thickness in Y.
// Corner at (x0, z0); legs run dx along X and dz along Z (signs give direction).
module gusset_xz(x0, z0, dx, dz, y0, y1)
    translate([0, min(y0,y1), 0]) rotate([90,0,0]) mirror([0,0,1])
        linear_extrude(abs(y1-y0)) polygon([[x0,z0],[x0+dx,z0],[x0,z0+dz]]);
// Same in the plane spanned by Y and Z, thickness in X.
module gusset_yz(y0, z0, dy, dz, x0, x1)
    translate([min(x0,x1), 0, 0]) rotate([90,0,90])
        linear_extrude(abs(x1-x0)) polygon([[y0,z0],[y0+dy,z0],[y0,z0+dz]]);

module base_shell() {
    difference() {
        union() {
            difference() {
                rbox(-hb, hb, -wb, wb, 0, shell_h, 6);
                rbox(-hb+wall, hb-wall, -wb+wall, wb-wall, floor_t, shell_h+1, 3);
            }
            // crank towers: 8 mm thick, wide tapered foot
            for (s = [-1,1]) hull() {
                box(s*(tower_x-4), s*(tower_x+4), -12, 12, 0, crank_z+11);
                box(s*(tower_x-4), s*(tower_x+4), -28, 28, 0, 4);
            }
            // rock motor plate, 6 mm, with gussets to the floor and back wall
            box(mplate[0], mplate[1], 10, wb-wall, 0, 50);
            gusset_xz(mplate[1], floor_t, 12, 12, 8, 14);
            gusset_xz(mplate[1], floor_t, 30, 40, 60, wb-wall);
            gusset_xz(mplate[0], floor_t, -12, 40, 60, wb-wall);
            for (x = [pcb[0]+2, pcb[1]-2], y = [pcb[2]+2, pcb[3]-2])
                zcyl(x, y, 0, floor_t+5, 8);                          // PCB standoffs
            hull() {                                                  // endstop post
                box(83, 89, 30, 44, 0, 48);
                box(83, 89, 26, 48, 0, 4);
            }
            for (p = lid_screws)
                intersection() {
                    box(p[0]-3.5, p[0]+3.5, p[1]-4, p[1]+4, 0, shell_h);
                    box(-hb+1, hb-1, -wb+1, wb-1, 0, shell_h);
                }
        }
        for (s = [-1,1]) {
            xcyl(s*(tower_x-5), s*(tower_x+5), 0, crank_z, 6);               // shaft hole
            xcyl(s*(tower_x+4.1), s*(tower_x+4-brg_w-0.2), 0, crank_z, seat_d); // seat, arm side
        }
        // rock motor: centre slot and four slotted screw holes (belt tension)
        hull() for (d = [-3,3]) xcyl(mplate[0]-1, mplate[1]+1, rock_motor[0]+d*rock_u[0], rock_motor[1]+d*rock_u[1], 23);
        for (a = [-1,1], b = [-1,1])
            hull() for (d = [-3,3])
                xcyl(mplate[0]-1, mplate[1]+1, rock_motor[0]+a*15.5+d*rock_u[0], rock_motor[1]+b*15.5+d*rock_u[1], m3_clr, 24);
        for (x = [pcb[0]+2, pcb[1]-2], y = [pcb[2]+2, pcb[3]-2]) zcyl(x, y, 1, 20, m3_tap, 24);
        panel_holes();                                               // controls in the front wall
        box(usb_x-6, usb_x+6, -wb-1, -wb+wall+1, 8, 16);            // USB
        ycyl(jack_x, wb-wall-1, wb+1, 22, 11.2);                     // DC jack
        for (z = [34, 42]) hull() for (y = [32, 42]) xcyl(82, 90, y, z, 3.2, 24); // endstop slots
        for (p = lid_screws) zcyl(p[0], p[1], shell_h-14, shell_h+1, m3_tap, 24);
    }
}

// Stacking tongue (on top of the base lid and of every rail) and its cross bolt.
module tongue_block(z0)
    box(lift_x-fl_in+0.3, lift_x+fl_in-0.3, back_y0+0.3, back_y1, z0, z0+tongue);
module cross_bolt(z)                       // M3 x 30 along X through rail, tongue, rail
    xcyl(lift_x-fl_out-1, lift_x+fl_out+1, bolt_y, z, m3_clr, 24);

module base_lid() {
    difference() {
        union() {
            rbox(-hb, hb, -wb, wb, shell_h, base_h, 6);
            for (mx = [0,1], my = [0,1]) mirror([mx,0,0]) mirror([0,my,0]) tongue_block(base_h-1);
        }
        for (s = [-1,1]) {
            box(s*87, s*101.75, -36, 36, shell_h-1, base_h+1);                         // crank arm + flag
            box(s*101.75, s*(lift_x+7.25), -36, 36, shell_h-1, base_h+1);              // yoke beam
            box(s*(lift_x-7.25), s*(lift_x+7.25), -(lift_y+lifter_t+0.2), lift_y+lifter_t+0.2,
                shell_h-1, base_h+1);                                                  // lifters
        }
        box(-82, -58, -22, 22, shell_h-1, shell_h+2);                // 60T pulley pocket
        zcyl(-85, -50, shell_h-1, base_h+1, 12);                     // roll motor cable
        for (p = lid_screws) {
            zcyl(p[0], p[1], shell_h-1, base_h+1, m3_clr, 24);
            translate([p[0], p[1], base_h-1.8]) cylinder(d1=m3_clr, d2=6.6, h=1.81, $fn=24);
        }
        for (mx = [0,1], my = [0,1]) mirror([mx,0,0]) mirror([0,my,0]) cross_bolt(base_h+5);
    }
}

// Controls, cut straight into the 4 mm front wall of the base shell (there is
// no separate front panel). The OLED, encoder and button mount from inside.
module panel_holes() {
    box(52-12.5, 52+12.5, -wb-1, -wb+wall+1, 34-7, 34+7);              // OLED window 25 x 14
    for (a = [-1,1], b = [-1,1]) ycyl(52+a*11.75, -wb-1, -wb+wall+1, 32+b*11.9, 2.2, 16); // OLED M2
    ycyl(76, -wb-1, -wb+wall+1, 37, 7.4);                             // encoder
    ycyl(76, -wb-1, -wb+wall+1, 18, 12.3);                            // MIX button
}

// Crank arm, +X (with home flag) or -X. phi = crank angle of this arm's pin.
// A solid 12 mm disc-and-lobe, no thin web.
module crank_arm(s, phi) {
    mirror([s < 0 ? 1 : 0, 0, 0]) translate([0, 0, crank_z]) rotate([phi,0,0])
    difference() {
        union() {
            hull() { xcyl(lift_x-21, lift_x-9, 0, 0, 18); xcyl(lift_x-15, lift_x-9, crank_r, 0, 15); }
            xcyl(tower_x+3.5, lift_x-20.9, 0, 0, 8);                              // race boss
            if (s > 0) hull() {                                                   // home flag
                xcyl(lift_x-21, lift_x-9, 0, 0, 10);
                box(lift_x-21, lift_x-9, -3, 3, -30, -26);
            }
        }
        xcyl(0, 200, 0, 0, bore, 32);
        xcyl(lift_x-25, lift_x, crank_r, 0, m5_clr, 32);
        // grub screw on +Z, nut slot open to the hub's inner end face
        translate([lift_x-17, 0, 0]) {
            zcyl(0, 0, 0, 10, 3.1, 24);
            box(-2.9 - 5, 2.9, -2.9, 2.9, 3.4, 6.0);
        }
    }
}

// Scotch-yoke beam carrying the two lifters at one end. z_off = crank height offset.
module yoke_beam(s, z_off=0, screws=true) {
    mirror([s < 0 ? 1 : 0, 0, 0]) translate([0, 0, crank_z + z_off])
    difference() {
        union() {
            box(lift_x-8, lift_x+7, -33, 33, -beam_h/2, beam_h/2);
            box(lift_x-7, lift_x+7, -(lift_y+lifter_t), lift_y+lifter_t, -beam_h/2, beam_h/2);
        }
        box(lift_x-9, lift_x+8, -(crank_r+slot_h/2), crank_r+slot_h/2, -slot_h/2, slot_h/2);
        if (screws) for (sy = [-1,1], dx = [-3.5,3.5]) {
            zcyl(lift_x+dx, sy*(lift_y+lifter_t/2), -beam_h, beam_h, m3_clr, 24);
            zcyl(lift_x+dx, sy*(lift_y+lifter_t/2), -beam_h, -beam_h/2+4, 6, 24);
        }
    }
}

// GT2 60T rock pulley, printed, on the crankshaft. Local axis Z.
module pulley60_local() {
    difference() {
        union() {
            cylinder(d=22, h=8);
            translate([0,0,8]) cylinder(d=42, h=1.5);
            translate([0,0,9.5]) gt2_ring(60, 7);
            translate([0,0,16.5]) cylinder(d=42, h=1.5);
        }
        translate([0,0,-1]) cylinder(d=bore, h=20, $fn=32);
        grub_m3(4, 11, 0);
    }
}
module pulley60() translate([-80, 0, crank_z]) rotate([0,90,0]) pulley60_local();

// =================================================================== RAILS
// Guard-rail segment: thick U channel, modelled at the (+X, +Y) corner. The
// same part fits all four corners. A 10 mm tongue on top fits a notch at the
// bottom of the next segment, held by one M3 x 30 bolt across.
module rail_seg(len, z0=0) {
    translate([0, 0, z0]) difference() {
        union() {
            hull() {                                                   // back
                box(lift_x-fl_out+2, lift_x+fl_out-2, back_y0, back_y1, 0, len);
                box(lift_x-fl_out, lift_x+fl_out, back_y0, back_y1-2, 0, len);
            }
            box(lift_x-fl_out, lift_x-fl_in, lift_y, back_y0+0.01, 0, len);    // flanges
            box(lift_x+fl_in,  lift_x+fl_out, lift_y, back_y0+0.01, 0, len);
            tongue_block(len);
        }
        box(lift_x-fl_in, lift_x+fl_in, back_y0-0.01, back_y1+1, -1, tongue+0.5); // notch
        cross_bolt(5);
        cross_bolt(len+5);
        for (sx = [-1,1]) translate([lift_x+sx*(fl_out+0.01), bolt_y, 5]) rotate([0, sx*90, 0])
            translate([0,0,-2.5]) rotate([0,0,30]) hexagon(5.8, 3);        // nut / head pockets
    }
}

// Top lid frame: an 8 mm ring with solid corner blocks over the rail tongues.
module lid_frame(z0) {
    ox = lift_x + fl_out + 0.7;  oy = back_y1 + 1.7;
    translate([0, 0, z0]) difference() {
        union() {
            difference() {
                rbox(-ox, ox, -oy, oy, 0, 8, 6);
                rbox(-(lift_x-fl_out-0.5), lift_x-fl_out-0.5, -(lift_y+3), lift_y+3, -1, 9, 4);
            }
            for (sx = [-1,1], sy = [-1,1])
                box(sx*(lift_x-fl_out-0.5), sx*ox, sy*(lift_y-1), sy*oy, 0, 14);
        }
        for (mx = [0,1], my = [0,1]) mirror([mx,0,0]) mirror([0,my,0]) {
            box(lift_x-fl_in, lift_x+fl_in, back_y0, back_y1+0.3, -1, tongue+0.5);
            box(lift_x-lifter_w/2-0.5, lift_x+lifter_w/2+0.5, lift_y-0.5, back_y0-0.1, -1, 15);
            xcyl(lift_x-ox-1, lift_x+ox, bolt_y, 5, m3_clr, 24);
        }
    }
}

// ================================================================= LIFTERS
// Local frame: X centred (width 14), Y = 0 inner face .. 12 outer face, Z along
// the bar. Standard segment: 6 mm outer-half tongue below 0, full section 0..70,
// 6 mm inner-half lap 70..90. The tongue overlaps the segment below.
module lifter_pin(zp) {
    ycyl(0, -1, lifter_t+1, zp, m4_clr, 24);
    ycyl(0, lifter_t-4.5, lifter_t+1, zp, 7.6, 32);                   // M4 head
    translate([0, -0.01, zp]) rotate([-90,0,0]) rotate([0,0,30]) hexagon(7.2, 3.5); // nut
}
module lap_csk(zs) for (z = zs) {                                     // lower part of a lap
    ycyl(0, -1, lifter_t, z, m3_clr, 24);
    translate([0, -0.01, z]) rotate([-90,0,0]) cylinder(d1=6.4, d2=m3_clr, h=1.7, $fn=24);
}
module lap_slot(zs) for (z = zs) {                                    // tongue: slot + nut pocket
    hull() for (d = [-4,4]) ycyl(0, -1, lifter_t+1, z+d, m3_clr, 24);
    hull() for (d = [-4,4]) translate([0, lifter_t-3, z+d]) rotate([-90,0,0]) rotate([0,0,30]) hexagon(5.8, 4);
}
hw = lifter_w/2;
module lifter_std() {
    difference() {
        union() {
            box(-hw, hw, lifter_t/2, lifter_t, -lap, 0);
            box(-hw, hw, 0, lifter_t, 0, 90-lap);
            box(-hw, hw, 0, lifter_t/2, 90-lap, 90);
        }
        lifter_pin(seg_pin);
        lap_csk([90-15, 90-5]);
        lap_slot([-15, -5]);
    }
}
module lifter_L1(s, screws=true) {   // s = +1 cap end (longer), -1 drive end
    len = L1_len + s*bias;
    difference() {
        union() {
            box(-hw, hw, 0, lifter_t, screws ? 0 : -1, len-lap);
            box(-hw, hw, 0, lifter_t/2, len-lap, len);
            if (!screws) gusset_yz(0, 0, -8, 8, -hw, hw);             // fillet onto the beam
        }
        lifter_pin(len - 24);
        lap_csk([len-15, len-5]);
        if (screws) for (dx = [-3.5,3.5]) zcyl(dx, lifter_t/2, -1, 14, m3_tap, 24);
    }
}

// Yoke beam and its two level 1 lifters as one U-shaped part (one per end).
// s = +1 cap end, -1 drive end; z_off = crank height offset.
module yoke_lifter(s, z_off=0) {
    yoke_beam(s, z_off, screws=false);
    for (sy = [-1,1])
        translate([s*lift_x, sy*lift_y, beam_top + z_off]) rotate(sy > 0 ? [0,0,0] : [0,0,180])
            lifter_L1(s, screws=false);
}

// =================================================================== DECK
// Deck-local frame: X, Y as global, z = 0 at the deck underside.
back_t = 4.3;  lip_t = 5;
module deck_frame() {
    bars = [drive_bar_x, centre_bar_x];
    difference() {
        union() {
            box(-hx, hx, -hy, hy, 0, deck_floor);
            box(-(boss_x0-0.5), boss_x0-0.5, hy-back_t, hy, 0, back_top);         // back wall
            gusset_yz(hy-back_t, deck_floor, -4, 4, -(boss_x0-0.5), boss_x0-0.5); // its fillet
            box(-(boss_x0-0.5), boss_x0-0.5, hy-back_t-1, hy, back_top-5, back_top); // top bead
            for (x = [-60, 0, 60]) gusset_yz(hy-0.01, deck_floor-0.01, 8, back_top-6, x-2.5, x+2.5); // buttresses
            box(-90, 90, hy-0.01, hy+8, 0, deck_floor);                           // buttress foot strip
            box(-x_in, x_in, -hy, -hy+lip_t, 0, lip_h);                           // front lip
            for (s = [-1,1]) end_plate(s);                                        // end plates, printed in place
            for (xb = bars) hull() {                                              // bar posts
                box(xb-bar_w/2, xb+bar_w/2, -hy, -hy+lip_t, 0, bar_z0);
                box(xb-bar_w/2-6, xb+bar_w/2+6, -hy, -hy+lip_t, 0, lip_h);
            }
        }
        for (s = [-1,1]) end_plate_holes(s);
        xcyl(-x_in-1, collar_x0 + 21, roller_ys[0], roller_z, 21);  // clear roller 1's drive collar (was 0.5 mm into the lip)
        for (xb = bars) {
            ycyl(xb, hy-back_t-2, hy+1, 30, m3_clr, 24);                    // bar, back screw
            zcyl(xb, -hy+lip_t/2, bar_z0-12, bar_z0+1, m3_tap, 24);         // bar, front screw
        }
    }
}

// End plate: 8 mm plate, full-depth pin bosses. Printed upright as part of the
// deck, so every boss underside is a 45 degree slope: a strip along the outer
// 3.5 mm slopes down to the plate, and the rest slopes up from that strip. The
// strip stays clear of the drive collars and O-rings (|y| <= 53.5).
boss_strip = hy - 3.5;
module end_plate(s) {          // s = -1 drive end (round pin holes), +1 cap end (slots, bumpers)
    box(s*x_in, s*hx, -hy, hy, 0, plate_top);
    for (sy = [-1,1]) {
        hull() {
            box(s*boss_x0, s*hx, sy*boss_strip, sy*hy, boss_z0, plate_top);
            box(s*boss_x0, s*hx, sy*boss_y0, sy*hy, boss_z0 + (boss_strip - boss_y0), plate_top);
        }
        hull() {
            box(s*boss_x0, s*hx, sy*boss_strip, sy*hy, boss_z0, boss_z0 + 0.01);
            box(s*(x_in-0.01), s*hx, sy*boss_strip, sy*hy, boss_z0 - (x_in - boss_x0), boss_z0);
        }
    }
    if (s > 0) for (y = valley_ys) dome(x_in, y, bottle_z, -1);
}
module end_plate_holes(s) {
        for (y = roller_ys) {
            xcyl(s*(x_in-1), s*(x_in+brg_w+0.2), y, roller_z, seat_d);      // bearing seat
            xcyl(s*(x_in-1), s*(hx+1), y, roller_z, 6.5);                    // shaft clearance
        }
        for (sy = [-1,1]) {                                                 // deck pins
            if (s < 0) ycyl(-lift_x, sy*(boss_y0-1), sy*(hy+1), pin_dz, m4_clr, 24);
            else hull() for (x = [lift_x-0.3, lift_x+6]) ycyl(x, sy*(boss_y0-1), sy*(hy+1), pin_dz, m4_clr, 24);
        }
        if (s < 0) for (p = [[30,8],[30,26],[52,26],[-29,32],[0,32]])
            xcyl(-hx-1, -hx+7, p[0], p[1], m3_tap, 24);                     // bracket + guard
}

// Stop bar: 8 x 12 mm solid bar, sits on a post on the front lip.
module stop_bar(xc, both) {
    difference() {
        union() {
            box(xc-bar_w/2, xc+bar_w/2, -hy, hy-back_t, bar_z0, bar_z1);
            for (y = valley_ys) {
                dome(xc+bar_w/2, y, bottle_z, 1);
                if (both) dome(xc-bar_w/2, y, bottle_z, -1);
            }
        }
        zcyl(xc, -hy+lip_t/2, bar_z0-1, bar_z1+1, m3_clr, 24);
        zcyl(xc, -hy+lip_t/2, bar_z1-3, bar_z1+1, 6.2, 24);
        ycyl(xc, hy-back_t-12, hy, 30, m3_tap, 24);
    }
}

// Roller parts, local axis Z
module drive_collar_local() {      // two O-ring grooves G1 / G2, 14 mm root
    difference() {
        union() {
            cylinder(d=8, h=0.6);
            translate([0,0,0.5]) cylinder(d=16, h=7);
            translate([0,0,7.5])  cylinder(d=19, h=1.5);
            translate([0,0,9])    cylinder(d=14, h=3.4);
            translate([0,0,12.4]) cylinder(d=19, h=2);
            translate([0,0,14.4]) cylinder(d=14, h=3.4);
            translate([0,0,17.8]) cylinder(d=19, h=1.5);
        }
        translate([0,0,-1]) cylinder(d=bore, h=30, $fn=32);
        grub_m3(4.2, 8, 0);
    }
}
module end_collar_local() {
    difference() {
        union() { cylinder(d=8, h=0.6); translate([0,0,0.5]) cylinder(d=10, h=9); }
        translate([0,0,-1]) cylinder(d=bore, h=12, $fn=32);
    }
}
core_len = (core_x1 - core_x0) / 2;   // 99
drive_len = 19.3;                     // drive collar length (incl. 0.5 mm race spacer)
end_len   = 9.5;                      // end collar length
module core_local() {
    difference() {
        hull() {
            cylinder(d=11, h=core_len);
            translate([0,0,0.5]) cylinder(d=12, h=core_len-1);
        }
        translate([0,0,-1]) cylinder(d=bore, h=core_len+2, $fn=32);
    }
}
// Drive-end roller: groove collar and first core in one piece, local axis Z with
// the core end at z = 0 (print it standing on that end, collar up). A 45 degree
// cone under the collar flange means nothing overhangs.
module roller_drive_local() {
    difference() {
        union() {
            core_local();
            translate([0, 0, core_len + 0.2 - 3.5]) cylinder(d1=12, d2=19, h=3.5); // under the flange
            translate([0, 0, core_len + drive_len + 0.2]) mirror([0,0,1]) drive_collar_local();
        }
        translate([0,0,-1]) cylinder(d=bore, h=core_len + drive_len + 2, $fn=32);
    }
}
// Cap-end roller: second core and the end spacer in one piece, core end at z = 0.
module roller_cap_local() {
    difference() {
        union() {
            core_local();
            translate([0, 0, core_len + end_len]) mirror([0,0,1]) end_collar_local();
        }
        translate([0,0,-1]) cylinder(d=bore, h=core_len + end_len + 2, $fn=32);
    }
}
module double_pulley_local() {     // two GT2 20T rings: V1 (level above) and V2 (motor or level above)
    difference() {
        union() {
            cylinder(d=16, h=1);
            translate([0,0,1])    gt2_ring(20, 7);
            translate([0,0,8])    cylinder(d=16, h=1.5);
            translate([0,0,9.5])  gt2_ring(20, 7);
            translate([0,0,16.5]) cylinder(d=16, h=1);
            translate([0,0,17.5]) cylinder(d=16, h=7.5);
        }
        translate([0,0,-1]) cylinder(d=bore, h=30, $fn=32);
        grub_m3(21.25, 8, 25);
    }
}

module roller_parts() {
    for (y = roller_ys) {
        translate([collar_x0 + drive_len + 0.2 + core_len, y, roller_z]) rotate([0,-90,0]) roller_drive_local();
        translate([core_x0 + core_len, y, roller_z]) rotate([0,90,0]) roller_cap_local();
    }
    translate([pulley_x0, roller_ys[1], roller_z]) rotate([0,-90,0]) double_pulley_local();
}

// Roll-motor bracket (level 1 only): one solid box-section part, 6 mm walls,
// bolts to the -X end plate.
module motor_bracket() {
    mp0 = motor_y - 25;  mp1 = motor_y + 25;
    mf = motor_face_x;
    difference() {
        union() {
            box(-hx-6, -hx, 22, hy, deck_floor, plate_top);                   // mount plate
            box(mf+6, -hx-6, 22, hy, plate_top-9, plate_top);                 // top arm
            box(mf, -hx-6, hy-6, hy, deck_floor, plate_top);                  // side web
            box(mf, mf+6, mp0, mp1, roller_z-21, plate_top);                  // motor plate
        }
        for (p = [[30,8],[30,26],[52,26]]) {
            xcyl(-hx-7, -hx+1, p[0], p[1], m3_clr, 24);
            xcyl(mf+7, -hx-3, p[0], p[1], 6.5, 24);                           // head access
        }
        hull() for (d = [-3,3]) xcyl(mf-1, mf+7, motor_y+d, roller_z, 23);
        for (a = [-1,1], b = [-1,1]) hull() for (d = [-3,3])
            xcyl(mf-1, mf+7, motor_y+a*15.5+d, roller_z+b*15.5, m3_clr, 24);
    }
}

// Belt guard over the GT2 loop that runs up to the next level (levels 1 and 2):
// a 3 mm U channel with a solid 6 mm mounting block.
module belt_guard() {
    gy0 = -32; gy1 = 2;  gb = -152;
    difference() {
        union() {
            box(-hx-6, -hx, gy0, gy1, boss_z0, plate_top);                    // mount block
            box(gb-3, gb, gy0, gy1, 8, 100);                                  // back
            box(gb-3, -hx-6, gy0, gy0+3, boss_z0, 100);                       // sides
            box(gb-3, -hx-6, gy1-3, gy1, boss_z0, 100);
            box(gb-3, -hx-6, gy0, gy0+3, 8, boss_z0);
            gusset_xz(-hx-6, boss_z0, -10, -10, gy0, gy0+3);
        }
        for (y = [-29, 0]) {
            xcyl(-hx-7, -hx+1, y, 32, m3_clr, 24);
            xcyl(gb-4, -hx-3, y, 32, 6.5, 24);                                // head access
        }
    }
}

// ================================================================ FIT TEST
module fit_test() {
    difference() {
        box(0, 92, 0, 30, 0, 6);
        for (i = [0:3]) {
            translate([12 + i*22, 10, 1]) cylinder(d=brg_od + (i-1)*0.1, h=10);
            translate([12 + i*22, 10, -1]) cylinder(d=6, h=10);
            for (k = [0:i]) box(5 + i*22 + k*2.5, 6 + i*22 + k*2.5, -1, 1.5, -1, 10); // notch count = i+1
        }
        for (i = [0:3]) translate([10 + i*10, 24, -1]) cylinder(d=5 + i*0.1, h=10, $fn=32);
        translate([56, 24, -1]) cylinder(d=m4_clr, h=10, $fn=24);
        translate([66, 24, -1]) cylinder(d=m3_tap, h=10, $fn=24);
        translate([66, 24, 3.5]) hexagon(5.7, 3);
        translate([80, 24, -1]) cylinder(d=m3_clr, h=10, $fn=24);
    }
    // the deck's bearing seats print sideways: check them here too
    // (1 notch = nominal, 2 notches = +0.1 mm)
    difference() {
        box(0, 48, -14, -6, 0, 26);
        for (i = [0,1]) {
            ycyl(12 + i*24, -14-1, -14+brg_w+0.2, roller_z, seat_d + i*0.1);
            ycyl(12 + i*24, -15, -5, roller_z, 6.5);
            for (k = [0:i]) box(3 + i*24 + k*2.5, 4 + i*24 + k*2.5, -15, -5, 24.5, 27);
        }
    }
    // short rail and lifter stub to check the sliding fit
    translate([0, -lift_y + 40, 0]) rail_seg(25);
    translate([150, 40, 0]) box(-hw, hw, 0, lifter_t, 0, 30);
}

// ============================================================ PRINT LAYOUT
// Each part turned onto the bed (z = 0).
module print_part(p) {
    if (p == "base_shell") base_shell();
    else if (p == "base_lid") translate([0,0,-shell_h]) base_lid();
    else if (p == "crank_arm_cap") translate([0,0,lift_x-9]) rotate([0,90,0]) translate([0,0,-crank_z]) crank_arm(1, 90);
    else if (p == "crank_arm_drive") translate([0,0,lift_x-9]) rotate([0,-90,0]) translate([0,0,-crank_z]) crank_arm(-1, 90);
    else if (p == "yoke_lifter_cap") translate([0,0,lift_x+7]) rotate([0,90,0]) translate([0,0,-crank_z]) yoke_lifter(1);
    else if (p == "yoke_lifter_drive") translate([0,0,lift_x+7]) rotate([0,-90,0]) translate([0,0,-crank_z]) yoke_lifter(-1);
    else if (p == "pulley_60T") pulley60_local();
    else if (p == "rail_L1") rail_seg(rail_L1);
    else if (p == "rail") rail_seg(pitch);
    else if (p == "lifter") rotate([0,-90,0]) translate([hw,0,lap]) lifter_std();
    else if (p == "deck") deck_frame();
    else if (p == "stop_bar_drive") translate([0,0,-bar_z0]) stop_bar(drive_bar_x, false);
    else if (p == "stop_bar_centre") translate([0,0,-bar_z0]) stop_bar(centre_bar_x, true);
    else if (p == "roller_drive") roller_drive_local();
    else if (p == "roller_cap") roller_cap_local();
    else if (p == "double_pulley") double_pulley_local();
    else if (p == "motor_bracket") rotate([180,0,0]) translate([0, 0, -plate_top]) motor_bracket();
    else if (p == "belt_guard") translate([0,0,155]) rotate([0,-90,0]) belt_guard();
    else if (p == "lid_frame") lid_frame(0);
    else if (p == "fit_test") fit_test();
}

if (part != "none") print_part(part);
