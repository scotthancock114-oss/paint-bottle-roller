# Paint Bottle Roller v1 — Design

Nov 24, 2026 · @Scott Hancock

## Summary

The design is now a modular, lab-style roller-rocker. You start with a base plus 1 or 2 levels and can add up to **3 levels**. Each level holds 6 bottles lying lengthwise, and the levels are **90 mm apart, so you can reach in and load or grab bottles by hand**. **One roll motor on level 1 spins every level** through GT2 belts. **One rock motor in the base** raises and lowers the two ends of every level in opposition, by ±19 mm (about ±10°). Every level hangs from the same four lifter bars, so every level gets exactly the same motion.

| Stack | Bottles | Height |
| --- | --- | --- |
| Base + 1 level | 6 | about 149 mm |
| Base + 2 levels | 12 | about 239 mm |
| Base + 3 levels (maximum) | 18 | about 329 mm |

The footprint is 260 × 152 mm, or about 296 mm long including the roll motor on level 1. The main (low-cost) build reuses your Ender 3 parts and costs about **$73 for 1 level, $90 for 2 and $107 for 3** (see BOM). A live 3D model is in [Paint Bottle Roller v1](https://claude.ai/artifact/DkSobUsx3h77cGNqXTJV6U).

I'm still assuming a 26 × 92 mm bottle. Please measure one, because it sets the deck length.

## Layout and dimensions

Each level module adds 90 mm of height. That leaves about 49 mm between the top of a bottle and the underside of the level above, enough to reach in, lift a bottle clear of the rollers and take it out. The stack is limited to 3 levels. The 20 mm of rocking room is needed only once below level 1 and once under the lid, because all the levels move together.

Axes: **X** is the bottle axis, with the caps toward +X (the loading end) and the drive at −X. **Y** is depth. **Z** is up.

| Part | Size | Contents |
| --- | --- | --- |
| Base (fixed) | 260 × 152 × 55 mm | Rock motor, crankshaft with 2 cranks, lifter yokes, home switch, electronics, OLED, encoder and MIX button on the front |
| Rock clearance | 20 mm | Room for the deck ends to drop 19 mm |
| Level module (rocks) | 228 × 115 mm deck, 90 mm pitch | 4 rollers, 6 bottles, drip tray floor with a low front lip, 4 lifter segments, 4 guide-rail segments, 2 GT2 pulleys on roller 2 |
| Lid | Frame on the 4 rails | Holds the rail tops square, with 20 mm of headroom; open in the middle |

How the X length adds up: two bottles end to end take 192 mm, the end walls 8 mm and the drive zone (O-rings and pulleys) 22 mm. The lifters and rails sit at X = ±110 mm. The level 1 roll motor (an Ender 3 NEMA 17 with a 40 mm body, plus coupler) sticks out about 40 mm further at the drive end.

How the depth adds up: 4 rollers at 29 mm pitch span 103 mm, plus deck walls (115 mm total), lifter bars at Y = ±62 mm and guide rails at Y = ±70 mm, which makes the base 152 mm deep. The rails sit only at the four corners, so the front and the cap end of every level are open.

## Loading and unloading by hand

The 90 mm level pitch replaces the pull-out drawers from the previous revision. It costs 40 mm of height per level but needs no slides, clutches or extra width, and it keeps the single roll motor driving straight up through the belts.

- **Open front:** each deck has a full-height back wall but only a 10 mm lip at the front, and the guide rails sit at the corners. Reach in from the front at any level.
- **Front valley:** lift the bottle straight up and out.
- **Middle and back valleys:** lift the bottle about 20 mm so it clears the rollers, then slide it forward over the front rollers. The 49 mm of hand room above the bottles allows for this.
- **Cap end:** the outer bottle of each valley can also be pulled out by its cap from the +X end, over the low bumper rail.
- **Stop first:** press Stop (or hold the encoder) before reaching in. The stack parks caps up at about +13°, so bottles you drop in roll back against the drive-end stop.
- **Pinch points:** the lifters at the four corners move ±19 mm. Keep fingers out of the corners while it rocks. The motors run at low current, but treat them like any moving machine.

## Roller geometry

Each level has 4 rollers, 16 mm in diameter at 29 mm pitch, running the length of the deck. They form 3 valleys, and each valley holds 2 bottles end to end with both caps toward the loading end. Each bottle sits at a 43.7° contact angle with a 3 mm gap to its neighbours.

```latex
\sin\theta = \frac{p/2}{(D+d)/2} = \frac{14.5}{21} = 0.690 \;\Rightarrow\; \theta = 43.7^\circ \qquad h = \sqrt{21^2 - 14.5^2} = 15.2\ \text{mm}
```

Here D = 26 mm is the bottle, d = 16 mm is the roller (a 12 mm core with a silicone or TPU sleeve), p = 29 mm is the pitch, and h is the height of the bottle centre above the roller centres.

- **Gaps:** neighbouring bottles are p − D = 3 mm apart, so the labels never touch. The 13 mm gap between rollers is far too small for a bottle to fall through.
- **Other bottle sizes:** a 24 mm bottle sits at 46.5° with a 5 mm gap, and a 27 mm bottle at 42.4° with a 2 mm gap. Both work.
- **Stacking:** inside one 90 mm level there's a 3 mm floor, roller centres at 13 mm, bottle centres at 28.2 mm and bottle tops at 41.2 mm. That leaves about 49 mm under the next floor, enough to reach in and lift bottles out by hand.
- **End stops:** the drive-end wall and a centre stop bar stop the bottles, and a lift-out gate bar closes the cap end. Each stop has a 6 mm domed bumper on the bottle's axis, so the contact is at the centre of the cap or base, where nothing rubs.

## Roll drive (one motor for every level)

The roll motor is **one of your spare Ender 3 NEMA 17s** (40 mm body, about 0.4 Nm holding). It is mounted on the **level 1 deck** at the −X end and coupled directly to **roller 2**. It rocks with the deck, so no flexible coupling is needed between a fixed motor and a moving roller. At 3 levels it has about 4× torque margin (see Torque). A new 34 mm motor (\~$12) is an optional upgrade that is 6 mm shorter and lighter.

**Inside a level:** 28 × 3 mm NBR O-rings chain the rollers. Roller 2 drives roller 1, and roller 3 drives roller 4, on groove G1. Roller 2 drives roller 3 on groove G2. All four rollers turn the same way, so all six bottles turn the same way. The groove root is 14 mm, the belt path about 111 mm, and the stretch about 14 %. That grips well enough for this load without loading the bearings hard.

**Between levels:** roller 2 in every level carries two GT2 20T pulleys, on planes V1 (X ≈ −116) and V2 (X ≈ −123). A closed **GT2 6 mm × 220 mm** loop links roller 2 of one level to roller 2 of the next. Its centre distance is C = (220 − 40) / 2 = **90 mm**, exactly the level pitch. Level 1→2 runs on V1 and 2→3 on V2, so no pulley carries two belts.

**Why the belts survive the rocking:** every deck hangs on the same lifter bars, so all decks tilt identically and the distance between roller 2 axes never changes. The belts never stretch and relax.

**Tension:** each belt between levels needs a little take-up for print tolerance. The default is slotted holes where each lifter segment bolts to the one below: slide it up, then clamp. The alternative is a small spring idler on the deck end plate.

**Speed:** the target is 20 RPM at the bottle, which mixes without foaming. Bottle speed is 0.615 × roller speed, so the rollers run at 32.5 RPM. At 200 steps × 16 microsteps that is 32.5 × 3200 / 60 = **1733 Hz** on STEP. Boost runs the bottles at 40 RPM for 2 minutes.

**Reversal:** the cycle is run, ramp down, pause, then run the other way. Reversing stops bottles creeping toward one end and evens out sediment.

## Rocking (end lifters, like a lab roller-rocker)

There is no centre pin. Each deck is carried at its four corners by **vertical lifter bars** at X = ±110 mm, Y = ±62 mm. The −X and +X ends move up and down in opposition, so the deck tilts about its own middle without a physical pivot.

- **Lifters:** one printed lifter segment per level (90 mm), bolted end to end. Each lifter slides in a **fixed corner guide rail** at Y = ±70 mm, also one segment per level.
- **Deck pins:** each deck has four corner ears with pins. The −X pins sit in round holes. The +X pins ride in a short slot, which absorbs the \~3.3 mm change in horizontal length as the deck tilts.
- **Crankshaft:** one shaft in the 55 mm base carries two cranks set 180° apart, r = 19 mm. Each crank drives a yoke and conrod up to the lifter pair at that end, so each end moves **±19 mm**, about **±10°** of tilt.
- **Caps-up bias:** the +X (cap) end lifters are 5.8 mm longer, so the decks sit at +3° at mid-stroke. Paint is kept off the dropper tip most of the cycle.
- **Drive:** the rock motor (Ender NEMA 17) turns the crankshaft through a 20T : 60T GT2 belt, a 3 : 1 reduction.
- **Identical motion on every level:** all decks hang from the same lifters, so level 1 and level 3 tilt by exactly the same angle at the same instant.
- **Gravity balance:** the two ends move in opposition, so most of the weight cancels at the crankshaft. The motor mainly fights friction, the roll motor's weight at the −X end and any imbalance.
- **Home and park:** a flag on the crankshaft trips the Ender endstop at top dead centre of the cap end. Parking stops there, caps up.

Tilt at crank angle φ: h\_R = 5.8 + 19 sin φ, h\_L = −h\_R, tilt = asin((h\_R − h\_L) / 220 mm).

The default rock period is 20 s per cycle (adjustable 10 to 120 s), which is 3 RPM at the crank and 9 RPM at the motor.

## Torque

**Roll motor (worst case, 3 levels)**

| Load | Per level | 3 levels |
| --- | --- | --- |
| 8 × 625ZZ bearing drag (\~0.5 mNm each) | 4 mNm | 12 mNm |
| 3 O-rings, hysteresis (\~2 mNm each) | 6 mNm | 18 mNm |
| Rolling resistance, 6 bottles on silicone | \~3 mNm | 9 mNm |
| GT2 loops between levels (\~3 mNm each) |  | 6 mNm |
| **Total at roller 2** |  | **\~45 mNm** |

The Ender 3 NEMA 17 at 800 mA in StealthChop gives roughly 0.2 Nm usable at 32 RPM, about **4× margin** at 3 levels and 6× at 2 levels. A new 34 mm motor would give about 3.3×, and a 23 mm pancake only about 2.2× at 3 levels.

**Rock motor**

- A deck plus 6 full bottles is about 250 g, so 3 levels is about 0.75 kg on the lifters, plus the \~280 g roll motor at the −X end of level 1.
- The ends move in opposition, so the deck weight mostly cancels. Allow about 1.5 N of imbalance plus about 3.3 N from the roll motor, which is about 80 mNm at 19 mm, plus about 40 mNm of guide and conrod friction. That is about 120 mNm at the crankshaft.
- Through 3 : 1 that is **about 40 mNm at the motor**. An Ender 3 NEMA 17 (\~0.4 Nm) at 500 mA has a large margin, so the rock axis won't skip.

## Paint handling

- **Agitator balls:** 2 × 6 mm **316 stainless** balls per bottle. They do the real mixing as the bottle rolls and rocks. Avoid 52100 chrome steel, which rusts in water-based paint.
- **Leaks:** all caps point to +X and the deck is biased +3° caps up, so paint sits away from the dropper tip. Close caps firmly. Parking always ends caps up.
- **Drip trays:** each deck floor is a shallow tray under the rollers, so a leak stays on its own level and wipes out.
- **No walking off:** bottles touch axis-centred bumpers at both ends of each valley. Reversing direction each cycle also cancels creep.
- **No label wear:** bottles ride on soft silicone sleeves, all rollers turn at the same surface speed, and the O-ring chain means nothing slips against the label.
- **Is rocking needed?** Rolling alone keeps pigment suspended, but it leaves a ring of settled paint near the shoulder and the tip. A slow rock moves the agitator balls end to end and clears it. Rocking can be switched off in the menu.

## BOM

**The main build is now the low-cost one.** It reuses your Ender 3 parts, buys from AliExpress and prints everything it can. The new precision parts and upgrades from the earlier BOM are listed after it as optional upgrades. Both use the same printed parts and the same firmware.

**Where the old money went:** the plastic itself is only about $8 for the base and $6 per level. The rest is parts a printer can't make well:

| Premium cost | Base kit | Per level |
| --- | --- | --- |
| Electronics (ESP32, 2 × TMC2209, USB-C PD, OLED, encoder, jam sensor, wiring) | \~$65 | none |
| Motors and metal motion parts (new roll motor, aluminium pulleys, shafts, bearings, dampers) | \~$41 | \~$33 (ground shafts, MR105ZZ bearings, pulleys, pins) |
| Silicone sleeves, O-rings, balls | none | \~$14 |
| Screws, inserts, feet, filament | \~$23 | \~$10 |

That earlier BOM priced everything at single-unit Amazon prices and included upgrades you don't strictly need: a jam sensor, motor dampers, USB-C power, aluminium pulleys, ground shafts, new bearings and a new roll motor. The main build drops them, reuses your Ender 3 motors, bearings, pulleys, endstop and screws, and keeps only what a printer can't make.

### Main build (low cost)

All bearings come from your own stock, so the BOM buys none. It also reuses the Ender 3's two spare steppers, its GT2 20T motor pulleys, the Z endstop and its M3/M4/M5 screws. Prices are AliExpress prices, rounded.

**Base kit**

| Part | Qty | Cost |
| --- | --- | --- |
| ESP32 DevKitC | 1 | $5 |
| TMC2209 driver modules (keep these: they are what makes it quiet) | 2 | $10 |
| Roll motor and rock motor: Ender 3 NEMA 17s | 2 | $0 (owned) |
| 5 mm to 5 mm coupler (roll motor to roller 2) | 1 | $1 |
| Rock drive: Ender GT2 20T pulley, **printed 60T pulley**, GT2 200 mm closed loop | 1 set | $1 |
| Crankshaft: 5 mm steel rod in 625ZZ bearings; crank pins are M5 bolts in 625ZZ (bearings from your stock) | 1 set | $1 |
| 12 V 2 A wall adapter + DC jack (or any old 12 V brick) | 1 | $6 |
| MP1584 buck, SS54 diode, fuse | 1 set | $3 |
| 0.96" SSD1306 OLED, KY-040 encoder, push button | 1 each | $5 |
| Ender endstop (home switch) | 1 | $0 (owned) |
| Perfboard, JST plugs, wire, resistors | 1 lot | $5 |
| M3 heat-set inserts (screws from the Ender) | 1 lot | $4 |
| 316 stainless 6 mm balls, pack of 100 (covers 3 levels) | 1 | $6 |
| PETG for base, rails and lid (\~400 g) |  | $8 |
| **Base kit total** |  | **\~$56** |

**Per-level kit**

| Part | Qty | Cost |
| --- | --- | --- |
| 5 mm bright steel rod (hardware store or AliExpress), cut to 230 mm, as roller shafts | 4 | $4 |
| 625ZZ (or MR105ZZ) bearings from your stock, in the printed end plates | 8 | $0 (owned) |
| Silicone tube 12 × 16 mm (AliExpress) | 0.8 m | $3 |
| NBR O-rings 28 × 3 mm (from an assortment box) | 3 | $1 |
| GT2 20T pulleys, 5 mm bore (steel, bulk) | 2 | $2 |
| GT2 6 mm 220 mm closed loop | 1 | $1 |
| M4 bolts as corner pins, screws from the Ender | 1 lot | $1 |
| PETG for deck, lifter and rail segments (\~250 g) |  | $5 |
| **Per-level total** |  | **\~$17** |

| Stack | Budget | Premium |
| --- | --- | --- |
| 1 level (6 bottles) | **\~$73** | \~$172 |
| 2 levels (12 bottles) | **\~$90** | \~$219 |
| 3 levels (18 bottles) | **\~$107** | \~$266 |

**Tradeoffs compared with the premium parts**

- **Shipping:** AliExpress parts take 2 to 4 weeks. Buying the same parts on Amazon roughly doubles the electronics cost.
- **Roll motor:** the Ender 3 motor has a 40 mm body, so it sticks out 6 mm further and weighs about 60 g more on level 1. It has more torque than the 34 mm motor, so it is fine for 3 levels. Set the roll current to about 800 mA.
- **Shafts:** plain steel rod is less straight and round than ground shaft, so the rollers may run slightly less smoothly. Roll each rod on a sheet of glass and keep the straightest four for each level.
- **Bearings:** all from your own stock, so nothing to buy. The design uses 5 mm bore bearings: 8 per level for the rollers plus 4 for the crank. 625ZZ (16 mm OD) is the default and makes the roller end plates 1 mm thicker; if you have MR105ZZ (10 mm OD), use those and print the matching end plates. Spin each one and throw out any that feel gritty.
- **Printed 60T pulley:** fine at this load and speed. Print it in PETG at 0.12 mm layers.
- **Dropped upgrades:** no AS5600 jam sensor (StallGuard still detects jams), no motor dampers (print TPU pads if you have TPU), a smaller 0.96" OLED, and a 12 V brick instead of USB-C power.
- **Kept on purpose:** the TMC2209 drivers and the ESP32. Cheaper A4988 drivers would save about $6 but whine audibly, and quiet running was one of your requirements.
- **Even cheaper:** your Ender 3's LCD with its built-in knob could replace the OLED and encoder (saving about $5). The firmware would need its display and pin settings changed, which I can do if you want.

### Optional upgrades (the earlier premium build)

Buy any of these in place of the matching main-build part if you want the extra smoothness or features. The full premium build is listed for reference.

**Premium base kit**

| Part | Qty | Cost |
| --- | --- | --- |
| ESP32 DevKitC (WROOM-32) | 1 | $8 |
| TMC2209 driver module (UART) | 2 | $14 |
| Rock motor: Ender 3 NEMA 17 | 1 | $0 (owned) |
| Roll motor: NEMA 17, 34 mm body (\~0.28 Nm, 1.3 A, e.g. 17HS3401) | 1 | $12 |
| 5 mm to 5 mm coupler, roll motor to roller 2 | 1 | $2 |
| GT2 20T + 60T aluminium pulleys, GT2 6 mm 200 mm loop (rock drive) | 1 set | $10 |
| 8 mm ground rod 150 mm (crankshaft); bearings from your stock | 1 | $3 |
| M5 shoulder bolts for crank pins and conrods (bearings from your stock) | 4 | $4 |
| USB-C PD trigger board (12 V) | 1 | $12 |
| MP1584 5 V buck, SS54 diode, 2 A fuse and holder | 1 set | $5 |
| 1.3" SH1106 I²C OLED | 1 | $7 |
| KY-040 encoder + 12 mm MIX button | 1 each | $4 |
| Ender endstop (home switch) | 1 | $0 (owned) |
| AS5600 board + diametric magnet (jam sensor) | 1 | $5 |
| NEMA 17 vibration dampers | 2 | $6 |
| Wire, JST-XH, perfboard, 10 k and 1 k resistors | 1 lot | $10 |
| M3 heat-set inserts, M3 and M4 screws | 1 lot | $12 |
| Rubber feet | 4 | $3 |
| PETG for base, rails and lid (\~350 g) |  | $8 |
| **Premium base kit total** |  | **\~$125** |

**Premium per-level kit**

| Part | Qty | Cost |
| --- | --- | --- |
| 5 mm ground shaft, 230 mm (rotating roller shafts) | 4 | $12 |
| MR105ZZ bearings (from your stock) | 8 | $0 |
| Silicone tube 12 ID × 16 OD (roller sleeves) | 1 m | $8 |
| NBR O-ring 28 × 3 mm | 3 (+ spares) | $3 |
| GT2 20T aluminium pulley, 5 mm bore | 2 | $5 |
| GT2 6 mm 220 mm closed loop (to the level below) | 1 | $2 |
| M4 shoulder pins (deck corners) | 4 | $4 |
| 6 mm 316 stainless balls | 12 | $3 |
| Screws and inserts | 1 lot | $4 |
| PETG for deck, lifter and rail segments (\~250 g) |  | $6 |
| **Premium per-level total** |  | **\~$47** |

**Premium totals** (bearings from your stock): 1 level about $172, 2 levels about $219, 3 levels about $266.

Optional: a FYSETC E4 board (ESP32 with 4 TMC2208/2209 drivers onboard, \~$30) can replace the DevKit, both driver modules and the perfboard. The firmware pins would change. See Electronics.

## Printed parts

Default settings for the X1C: PETG, 0.4 mm nozzle, 0.2 mm layers, 4 walls, 25 % gyroid infill. Bearing seats are printed 0.1 mm undersize and pressed in.

The STLs and the full print list (with orientations and the hardware each part needs) are in [cad/README.md](../cad/README.md). Revision 3 merged parts to suit the 256 mm X1C bed: 25 parts for base + 1 level, 46 for 2 levels and 67 for 3. Revision 4 adds 45° chamfers to the outer edges and a 0.4 mm elephant-foot relief on every bed face, without touching any fit, sliding or bearing face.

| Part | Qty | Orientation | Notes |
| --- | --- | --- | --- |
| Base shell | 1 | floor down | crank towers, rock-motor plate, electronics bay; OLED, encoder and MIX button holes are in its front wall |
| Base lid | 1 | flat | holds the 4 guide rails |
| Crank arms | 2 (cap, drive) | flat | 100 % infill; the cap arm carries the home flag |
| Yoke + level 1 lifters | 2 (cap, drive) | flat on the outer face | one U-shaped part per end; the cap pair is 11.5 mm longer for the 3° caps-up bias |
| 60T rock pulley | 1 | flat | 0.12 mm layers |
| Guide-rail segment | 4 per level | standing upright | 104 mm at level 1, 90 mm above; tongue joint with one M3 × 30 cross bolt |
| Lifter segment | 4 per added level | lying flat | 90 mm, slotted lap joint for belt tension |
| Deck with end plates | 1 per level | tray side down | 244 × 123 mm; bearing seats, deck-pin bosses and cap-end bumpers in one part |
| Stop bars | 2 per level | flat | separate so they can be reprinted for another bottle length |
| Roller halves | 8 per level (4 drive, 4 cap) | standing on end | 12 mm core; the drive half carries the O-ring groove collar |
| Double 20T pulley | 1 per level | standing on end | roller 2, V1 and V2 belts |
| Roll motor bracket | 1 | top face down | level 1 only |
| Belt guard | 1 per level below the top | on its back | covers the GT2 loop |
| Top lid frame | 1 | flat | sits on the top rail tongues |

Print time is roughly 9 h for the base kit and 7 h per level.

## Electronics, wiring and pinout

**Power:** a 12 V 2 A brick (or a USB-C PD trigger as an upgrade) → 2 A fuse → SS54 reverse diode → 12 V bus for both TMC2209 VM pins, with a 100 µF capacitor at each driver. The MP1584 buck makes 5 V for the ESP32 VIN. The OLED, encoder, driver VIO and the optional AS5600 run from the ESP32 3V3.

**Drivers:** both TMC2209s share one UART line. ESP32 TX goes through a 1 k resistor to both PDN\_UART pins, and RX connects directly. Roll is address 0 (MS1 and MS2 to GND) and rock is address 1 (MS1 to 3V3). R\_sense is 0.11 Ω. Both run in StealthChop.

**Cables:** the roll motor lead runs up the −X rail to level 1 with a service loop, because the deck moves ±19 mm. The rock motor and home switch stay in the base.

| Function | ESP32 GPIO | Goes to |
| --- | --- | --- |
| Roll STEP / DIR / EN | 25 / 26 / 27 | TMC2209 #0 (EN active low) |
| Rock STEP / DIR / EN | 32 / 33 / 13 | TMC2209 #1 |
| TMC UART RX / TX | 16 / 17 | both PDN\_UART (TX via 1 k) |
| OLED SDA / SCL | 21 / 22 | 0.96" SSD1306 OLED (optional AS5600 on the same bus) |
| Encoder A / B / switch | 18 / 19 / 23 | KY-040 CLK / DT / SW |
| MIX button | 4 | momentary to GND |
| Home switch | 34 | Ender endstop, 10 k pull-up to 3V3; NC, so pressed reads HIGH |
| Running LED | 2 | onboard LED |

With a FYSETC E4 instead, use its onboard X and Y drivers and its fixed pins, and change only the pin block at the top of the firmware.

## Firmware and controls

The firmware is in PaintRoller.ino, with a platformio.ini. It uses FastAccelStepper, TMCStepper, U8g2, Preferences and WebServer. **It has not been compiled yet**, so expect a small fix or two on the first build.

- **One roll axis drives every level**, so the firmware does not change when you add a level. Only the roll current might: 800 mA by default for the Ender 3 motor. The display is a 0.96" SSD1306; for a 1.3" SH1106, swap the one-line display constructor.
- **Rock axis:** continuous crank rotation. Step rate = 3200 × 3 / period. The default period is 20 s.
- **Cycle:** run forward, ramp, pause, run reverse, ramp, pause, repeat for the session length. Then park caps up and wait for the next interval (default 10 min every 6 h).
- **Controls:** turn the encoder to scroll and click to edit. On the status screen, a long press starts a session when idle and stops one that is running. The MIX button starts a session, and a long press on MIX starts boost (40 RPM for 2 min).
- **Settings** survive power loss in NVS. The menu covers speed, run and pause times, session, interval, rocking on/off and period, boost, motor currents and jam detection.
- **Wi-Fi (optional):** the access point "PaintRoller" serves a page with the same settings and Mix / Boost / Stop buttons. Build with ENABLE\_WIFI=0 to drop it.
- **Jam detection (optional):** StallGuard on the roll driver, or the AS5600 watching a roller. A jam stops both motors and shows FAULT.
- **Parking:** the rock axis runs to the crankshaft home switch, so bottles always end caps up. It gives up after 150 s and shows a fault.

## Assembly and adding a level

**Base**

1. Press 608ZZ bearings into the base bosses. Fit the 8 mm crankshaft with the 60T pulley and both crank disks, set exactly 180° apart.
2. Mount the rock motor on dampers with its 20T pulley. Fit the 200 mm loop and tension it by sliding the motor.
3. Fit the conrods and yokes. Fit the home flag at top dead centre on the +X crank and place the endstop so it trips there.
4. Wire the electronics bay to the pinout above. Power up with no motors connected and check 12 V, 5 V and 3V3.
5. Fit the base lid plate and the first four guide-rail segments.

**Level 1**

6. Press the 625ZZ bearings into the deck's end plates from inside the tray. Sleeve the eight roller halves with silicone, lay them in, and push each rod through from outside. Then screw on the stop bars.
7. Fit the three O-rings: 2→1 and 3→4 on G1, 2→3 on G2.
8. Mount the roll motor bracket at −X and couple the Ender 3 motor to roller 2.
9. The level 1 lifters are part of the two yoke parts (the +X one is longer for the caps-up bias). Pin the deck to them.
10. Run the motor cable up the −X rail with a service loop.

**Adding a level (the same for levels 2, 3 and 4)**

11. Lift off the top lid frame. Stack four more 90 mm rail segments onto the dovetails.
12. Bolt four lifter segments onto the tops of the ones below, leaving the screws loose in their slots.
13. Pin the new deck into the lifters. Loop a GT2 220 belt over roller 2 of the level below and roller 2 of the new deck, on the free plane (V1 for level 2, V2 for level 3).
14. Slide the new lifter segments up until the belt is snug (it should deflect about 4 mm with a light finger), then tighten.
15. Fit the belt guard and put the lid back on. No wiring is needed. Stop at 3 levels.

## Test checklist

- [ ] 12 V, 5 V and 3V3 are correct, and the fuse is fitted.
- [ ] Both drivers answer on UART at boot (the serial log shows both addresses).
- [ ] Home switch reads LOW when free and HIGH when pressed. If not, flip HOME\_TRIGGERED\_LEVEL.
- [ ] Rock axis turns the crank smoothly by hand with the motor off, and both ends move in opposition.
- [ ] Measured tilt is about ±10° with a +3° caps-up bias, the same on every level (phone inclinometer on each deck).
- [ ] Parking stops caps up within one rock period.
- [ ] All 12 rollers on 2 levels turn the same direction. FWD is the direction you expect; if not, set ROLL\_DIR\_INVERT.
- [ ] Rollers at 32.5 RPM give bottles about 20 RPM (count a marked bottle for 30 s).
- [ ] No belt skipping or O-ring slip over a full rock cycle with all bottles loaded.
- [ ] Bottles stay in their valleys and do not walk into the bumpers over a 10 min session.
- [ ] Noise is acceptable at 1 m (StealthChop on both axes).
- [ ] A setting changed in the menu survives a power cycle.
- [ ] Holding a roller by hand triggers a jam fault, if jam detection is on.
- [ ] The Wi-Fi page loads at 192.168.4.1 and its buttons work, if Wi-Fi is on.
- [ ] Leak test: one bottle of water with a loose cap for one session leaves only the drip tray wet.

* [ ] With the stack parked, every bottle on every level can be lifted out by hand from the front or the cap end without touching the level above.
* [ ] With 3 levels and all 18 bottles loaded, the roll motor doesn't skip at 40 RPM boost.

## v2 ideas

- Swappable roller pitch plates for 35 ml AK and Scale75 bottles and for wider bottles.
- A cam-profiled crank for a dwell at each end of the rock, as some lab rockers do.
- Spring-loaded belt idlers, so adding a level needs no tension adjustment.
- Pogo-pin or magnetic deck pins for tool-free deck removal and cleaning.
- A small app or Home Assistant integration over MQTT, with a schedule per paint set.
- Load cell or AS5600 trend logging, to warn before a roller sleeve wears.
- A clear acrylic dust cover over the stack.
- An injection-friendly redesign of the deck and lifters if you want to make several.
