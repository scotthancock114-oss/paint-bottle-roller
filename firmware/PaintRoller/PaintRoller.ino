/*
  ===========================================================================
  Paint Bottle Roller v1  -  ESP32 firmware
  ===========================================================================
  What it does
    * ROLL motor (spare Ender 3 NEMA17 + TMC2209) rides on level 1 and turns roller 2 of
      that level directly. O-rings link the 4 rollers in each level, and a GT2
      220 mm belt on roller 2 carries the drive up to each module stacked above
      (90 mm level pitch, up to 3 levels), so one motor spins every bottle. It runs forward for RUN seconds,
      decelerates, pauses for PAUSE seconds, then runs in reverse, and repeats.
    * ROCK motor (NEMA17 + TMC2209) sits in the base and turns a crankshaft
      through a 20T:60T GT2 belt. Two cranks 180 deg apart drive the lifter
      bars at the two ends of the stack, so the cap end rises while the drive
      end falls (+/-19 mm, about +/-10 deg), like a lab roller-rocker. Every
      level hangs on the same lifters, so every level gets identical motion.
    * A SESSION lasts SESSION minutes (0 = run forever). After a session the
      crankshaft is parked caps-up (home switch on the crank) and the motors
      are switched off. A new session starts every INTERVAL minutes
      (0 = only when you ask for one).
    * MIX button: short press = start a session now, long press = BOOST
      (faster rolling for BOOST seconds, e.g. before a painting session).
    * Rotary encoder: click = open menu / edit / save, turn = scroll / change,
      hold (on the status screen) = start or stop a session.
    * Settings are stored in ESP32 flash (NVS) and survive power loss.
    * Optional Wi-Fi access point with a small web page (ENABLE_WIFI).
    * Optional jam detection using the TMC2209 StallGuard value (off by default,
      calibrate first - see the design doc's test checklist).

  Libraries (Arduino Library Manager or PlatformIO):
    * FastAccelStepper  (gin66)       - hardware step generation on ESP32
    * TMCStepper        (teemuatlut)  - UART configuration of the TMC2209
    * U8g2              (olikraus)    - 0.96" SSD1306 OLED (for a 1.3" SH1106, swap the constructor below)
  Board: "ESP32 Dev Module" (ESP32-WROOM-32 DevKitC, 38-pin).

  NOTE: this sketch has not been compiled or run on hardware yet. Expect to
  fix small things on first build; the structure and pin map are final.
  ===========================================================================
*/

#include <Arduino.h>
#include <Preferences.h>
#include <Wire.h>
#include <U8g2lib.h>
#include <FastAccelStepper.h>
#include <TMCStepper.h>
#include "driver/gpio.h"

#ifndef ENABLE_WIFI
#define ENABLE_WIFI 1          // set to 0 to build without the web page
#endif
#if ENABLE_WIFI
#include <WiFi.h>
#include <WebServer.h>
const char* AP_SSID = "PaintRoller";
const char* AP_PASS = "changeme123";   // >= 8 chars. CHANGE THIS.
#endif

// ---------------------------------------------------------------------------
// Pin map (ESP32 DevKitC). Avoid strapping pins 0, 2(LED ok), 5, 12, 15.
// ---------------------------------------------------------------------------
constexpr uint8_t PIN_ROLL_STEP = 25;
constexpr uint8_t PIN_ROLL_DIR  = 26;
constexpr uint8_t PIN_ROLL_EN   = 27;   // TMC2209 EN is active LOW
constexpr uint8_t PIN_ROCK_STEP = 32;
constexpr uint8_t PIN_ROCK_DIR  = 33;
constexpr uint8_t PIN_ROCK_EN   = 13;
constexpr uint8_t PIN_TMC_RX    = 16;   // Serial2 RX  <- PDN_UART (both drivers)
constexpr uint8_t PIN_TMC_TX    = 17;   // Serial2 TX  -> 1k resistor -> PDN_UART
constexpr uint8_t PIN_SDA       = 21;   // OLED
constexpr uint8_t PIN_SCL       = 22;
constexpr uint8_t PIN_ENC_A     = 18;   // KY-040 CLK
constexpr uint8_t PIN_ENC_B     = 19;   // KY-040 DT
constexpr uint8_t PIN_ENC_SW    = 23;   // KY-040 SW
constexpr uint8_t PIN_MIX_BTN   = 4;    // momentary to GND
constexpr uint8_t PIN_HOME_SW   = 34;   // input-only pin: fit external 10k pull-up to 3V3
constexpr uint8_t PIN_LED       = 2;    // on-board LED = "running"

// ---------------------------------------------------------------------------
// Mechanics - change these if you change the hardware
// ---------------------------------------------------------------------------
constexpr float    BOTTLE_DIA_MM     = 26.0f;  // measured bottle body diameter
constexpr float    ROLLER_DIA_MM     = 16.0f;  // roller OD over the grip sleeve
constexpr float    ROLL_MOTOR_PER_ROLLER = 1.0f; // motor is direct on a roller; level-to-level belts are 20T:20T
constexpr float    ROCK_MOTOR_PER_CRANK  = 3.0f; // 20T motor pulley : 60T crankshaft pulley
constexpr uint16_t MICROSTEPS        = 16;     // TMC2209 interpolates to 256 anyway
constexpr uint32_t STEPS_PER_REV     = 200UL * MICROSTEPS;
constexpr bool     ROLL_DIR_INVERT   = false;  // flip if "FWD" turns the wrong way
constexpr bool     ROCK_DIR_INVERT   = false;

// Home switch on the crankshaft: a flag presses it where the cap end is at its
// highest point (crank top dead centre), so the stack parks caps-up.
// A stock Ender 3 endstop wired S + GND is normally-closed: pressed reads HIGH.
constexpr bool     HAS_HOME_SWITCH   = true;
constexpr int      HOME_TRIGGERED_LEVEL = HIGH;  // check in the test checklist

// TMC2209 (BigTreeTech v1.3 style modules use 0.11 ohm sense resistors)
constexpr float    R_SENSE           = 0.11f;
constexpr uint8_t  ADDR_ROLL         = 0b00;   // MS1=GND MS2=GND
constexpr uint8_t  ADDR_ROCK         = 0b01;   // MS1=3V3 MS2=GND

constexpr uint32_t ROLL_ACCEL        = 600;    // steps/s^2, gentle = quiet
constexpr uint32_t ROCK_ACCEL        = 200;
constexpr uint32_t HOME_TIMEOUT_MS   = 150000; // give up parking after this (> one slowest rock period)

// ---------------------------------------------------------------------------
// Settings (persisted). All int16 so the menu and web page can share code.
// ---------------------------------------------------------------------------
constexpr uint32_t SETTINGS_MAGIC = 0x50525631;  // "PRV1" - bump if struct changes

struct Settings {
  uint32_t magic;
  int16_t bottleRpm;      // bottle speed in normal sessions
  int16_t runSec;         // run time per direction
  int16_t pauseSec;       // pause between directions
  int16_t sessionMin;     // session length, 0 = continuous
  int16_t intervalMin;    // start a session every N minutes, 0 = manual only
  int16_t rockOn;         // 1 = rock during sessions
  int16_t rockPeriodSec;  // one full tip-down/tip-up cycle
  int16_t boostRpm;       // bottle speed in boost
  int16_t boostSec;       // boost length
  int16_t rollmA;         // TMC2209 RMS current, roll motor
  int16_t rockmA;         // TMC2209 RMS current, rock motor
  int16_t stallOn;        // 1 = jam detection active
  int16_t stallThresh;    // SG_RESULT below this for 0.5 s = jam
};

Settings cfg;

void setDefaults() {
  cfg.magic         = SETTINGS_MAGIC;
  cfg.bottleRpm     = 20;
  cfg.runSec        = 120;
  cfg.pauseSec      = 5;
  cfg.sessionMin    = 10;
  cfg.intervalMin   = 360;   // every 6 h
  cfg.rockOn        = 1;
  cfg.rockPeriodSec = 20;
  cfg.boostRpm      = 40;
  cfg.boostSec      = 120;
  cfg.rollmA        = 800;   // Ender 3 NEMA17 drives up to 3 levels
  cfg.rockmA        = 500;
  cfg.stallOn       = 0;
  cfg.stallThresh   = 20;
}

Preferences prefs;

void loadSettings() {
  prefs.begin("roller", false);
  size_t n = prefs.getBytes("cfg", &cfg, sizeof(cfg));
  if (n != sizeof(cfg) || cfg.magic != SETTINGS_MAGIC) {
    setDefaults();
    prefs.putBytes("cfg", &cfg, sizeof(cfg));
  }
}

void saveSettings() {
  // NVS does wear-levelling; we only write when a value actually changed.
  prefs.putBytes("cfg", &cfg, sizeof(cfg));
}

// ---------------------------------------------------------------------------
// Menu definition: one table drives the OLED menu and the web page.
// ---------------------------------------------------------------------------
enum class Action : uint8_t { None, MixNow, Boost, Stop, Defaults, Back };

struct MenuItem {
  const char* label;
  const char* key;      // web form field name
  int16_t*    val;      // nullptr for actions
  int16_t     mn, mx, step;
  const char* unit;
  Action      action;
};

MenuItem menu[] = {
  {"Bottle speed",  "rpm",   &cfg.bottleRpm,     5,   40,  1, "rpm", Action::None},
  {"Run/direction", "run",   &cfg.runSec,       10, 1800, 10, "s",   Action::None},
  {"Pause",         "pause", &cfg.pauseSec,      0,   60,  1, "s",   Action::None},
  {"Session",       "sess",  &cfg.sessionMin,    0,  240,  1, "min", Action::None},
  {"Every",         "every", &cfg.intervalMin,   0, 1440, 15, "min", Action::None},
  {"Rocking",       "rock",  &cfg.rockOn,        0,    1,  1, "",    Action::None},
  {"Rock period",   "rockp", &cfg.rockPeriodSec,10,  120,  1, "s",   Action::None},
  {"Boost speed",   "brpm",  &cfg.boostRpm,     10,   60,  1, "rpm", Action::None},
  {"Boost time",    "bsec",  &cfg.boostSec,     30,  600, 10, "s",   Action::None},
  {"Roll current",  "rma",   &cfg.rollmA,      300, 1200, 50, "mA",  Action::None},
  {"Rock current",  "kma",   &cfg.rockmA,      300, 1200, 50, "mA",  Action::None},
  {"Jam detect",    "jam",   &cfg.stallOn,       0,    1,  1, "",    Action::None},
  {"Jam threshold", "jamt",  &cfg.stallThresh,   0,  255,  1, "",    Action::None},
  {"> Mix now",     nullptr, nullptr, 0, 0, 0, "", Action::MixNow},
  {"> Boost",       nullptr, nullptr, 0, 0, 0, "", Action::Boost},
  {"> Stop",        nullptr, nullptr, 0, 0, 0, "", Action::Stop},
  {"> Defaults",    nullptr, nullptr, 0, 0, 0, "", Action::Defaults},
  {"< Back",        nullptr, nullptr, 0, 0, 0, "", Action::Back},
};
constexpr int MENU_LEN = sizeof(menu) / sizeof(menu[0]);

// ---------------------------------------------------------------------------
// Hardware objects
// ---------------------------------------------------------------------------
U8G2_SSD1306_128X64_NONAME_F_HW_I2C oled(U8G2_R0, U8X8_PIN_NONE);
FastAccelStepperEngine engine;
FastAccelStepper* roll = nullptr;
FastAccelStepper* rock = nullptr;
TMC2209Stepper drvRoll(&Serial2, R_SENSE, ADDR_ROLL);
TMC2209Stepper drvRock(&Serial2, R_SENSE, ADDR_ROCK);
bool rollDrvOk = false, rockDrvOk = false;

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------
enum class Mode  : uint8_t { Idle, Session, Boost, Parking, Fault };
enum class Phase : uint8_t { RunFwd, StopA, PauseA, RunRev, StopB, PauseB };

Mode     mode = Mode::Idle;
Phase    phase = Phase::RunFwd;
uint32_t modeStart = 0;     // when the current session/boost started
uint32_t phaseStart = 0;    // when the current phase started
uint32_t idleStart = 0;     // when we last became idle (interval timer)
const char* faultMsg = "";
int      lastSG = -1;       // last StallGuard reading, shown on screen
uint8_t  stallCount = 0;

// Convert a bottle RPM to a roll-motor step rate.
uint32_t rollHz(int bottleRpm) {
  float rollerRpm = bottleRpm * BOTTLE_DIA_MM / ROLLER_DIA_MM;  // bottle turns slower
  float motorRpm  = rollerRpm * ROLL_MOTOR_PER_ROLLER;
  return (uint32_t)(motorRpm * STEPS_PER_REV / 60.0f);
}

// One crankshaft turn = one full rock cycle (cap end up, down, back up).
uint32_t rockHz() {
  return (uint32_t)(STEPS_PER_REV * ROCK_MOTOR_PER_CRANK / (float)max<int16_t>(cfg.rockPeriodSec, 1));
}

bool homeTriggered() {
  return digitalRead(PIN_HOME_SW) == HOME_TRIGGERED_LEVEL;
}

void applyCurrents() {
  if (rollDrvOk) drvRoll.rms_current(cfg.rollmA);
  if (rockDrvOk) drvRock.rms_current(cfg.rockmA);
}

void motorsOn()  { roll->enableOutputs(); rock->enableOutputs(); digitalWrite(PIN_LED, HIGH); }
void motorsOff() { roll->disableOutputs(); rock->disableOutputs(); digitalWrite(PIN_LED, LOW); }

int activeRpm() { return mode == Mode::Boost ? cfg.boostRpm : cfg.bottleRpm; }

void enterPhase(Phase p) {
  phase = p;
  phaseStart = millis();
  stallCount = 0;
  switch (p) {
    case Phase::RunFwd: roll->setSpeedInHz(rollHz(activeRpm())); roll->runForward();  break;
    case Phase::RunRev: roll->setSpeedInHz(rollHz(activeRpm())); roll->runBackward(); break;
    case Phase::StopA:
    case Phase::StopB:  roll->stopMove(); break;   // decelerates, no jerk
    default: break;                                 // pauses: nothing to do
  }
}

void startRun(bool boost) {
  if (mode == Mode::Fault) return;
  mode = boost ? Mode::Boost : Mode::Session;
  modeStart = millis();
  motorsOn();
  enterPhase(Phase::RunFwd);
  if (cfg.rockOn) {
    rock->setSpeedInHz(rockHz());
    rock->runForward();          // crank always turns the same way
  }
}

// Graceful end: stop rolling, then park the crank tip-up, then power down.
void endRun() {
  roll->stopMove();
  mode = Mode::Parking;
  modeStart = millis();
}

void fault(const char* msg) {
  roll->forceStop();
  rock->forceStop();
  motorsOff();
  faultMsg = msg;
  mode = Mode::Fault;
}

void finishParking() {
  rock->forceStop();
  motorsOff();
  mode = Mode::Idle;
  idleStart = millis();
}

void updateParking() {
  uint32_t now = millis();
  if (roll->isRunning()) return;                  // wait for rollers to stop
  if (!HAS_HOME_SWITCH || !cfg.rockOn) {
    if (!rock->isRunning() || !cfg.rockOn) { finishParking(); return; }
    rock->stopMove();                             // no switch: just stop
    return;
  }
  if (homeTriggered()) { finishParking(); return; }
  if (!rock->isRunning()) {                       // rocking was off: drive to home
    rock->enableOutputs();
    rock->setSpeedInHz(rockHz());
    rock->runForward();
  }
  if (now - modeStart > HOME_TIMEOUT_MS) fault("Home switch?");
}

// Jam detection: StallGuard falls toward 0 as load rises. Only checked while
// cruising (not accelerating) in a run phase.
void checkStall() {
  static uint32_t lastCheck = 0;
  uint32_t now = millis();
  if (now - lastCheck < 100) return;
  lastCheck = now;
  if (!rollDrvOk) return;
  lastSG = drvRoll.SG_RESULT();
  bool cruising = (phase == Phase::RunFwd || phase == Phase::RunRev) &&
                  (now - phaseStart > 3000);
  if (!cfg.stallOn || !cruising) { stallCount = 0; return; }
  if (lastSG < cfg.stallThresh) {
    if (++stallCount >= 5) fault("Roller jam");
  } else {
    stallCount = 0;
  }
}

void updateMotion() {
  uint32_t now = millis();
  switch (mode) {
    case Mode::Idle:
      if (cfg.intervalMin > 0 && now - idleStart >= (uint32_t)cfg.intervalMin * 60000UL)
        startRun(false);
      break;

    case Mode::Session:
    case Mode::Boost: {
      uint32_t limit = (mode == Mode::Boost) ? (uint32_t)cfg.boostSec * 1000UL
                                             : (uint32_t)cfg.sessionMin * 60000UL;
      if (limit > 0 && now - modeStart >= limit) { endRun(); break; }
      uint32_t inPhase = now - phaseStart;
      switch (phase) {
        case Phase::RunFwd: if (inPhase >= (uint32_t)cfg.runSec * 1000UL) enterPhase(Phase::StopA); break;
        case Phase::StopA:  if (!roll->isRunning()) enterPhase(Phase::PauseA); break;
        case Phase::PauseA: if (inPhase >= (uint32_t)cfg.pauseSec * 1000UL) enterPhase(Phase::RunRev); break;
        case Phase::RunRev: if (inPhase >= (uint32_t)cfg.runSec * 1000UL) enterPhase(Phase::StopB); break;
        case Phase::StopB:  if (!roll->isRunning()) enterPhase(Phase::PauseB); break;
        case Phase::PauseB: if (inPhase >= (uint32_t)cfg.pauseSec * 1000UL) enterPhase(Phase::RunFwd); break;
      }
      checkStall();
      break;
    }

    case Mode::Parking: updateParking(); break;
    case Mode::Fault:   break;
  }
}

// Called after a setting changed so a running session follows it at once.
void applyLiveChanges() {
  applyCurrents();
  if (mode == Mode::Session || mode == Mode::Boost) {
    if (phase == Phase::RunFwd || phase == Phase::RunRev) {
      roll->setSpeedInHz(rollHz(activeRpm()));
      roll->applySpeedAcceleration();
    }
    if (cfg.rockOn) {
      rock->setSpeedInHz(rockHz());
      if (rock->isRunning()) rock->applySpeedAcceleration(); else rock->runForward();
    } else if (rock->isRunning()) {
      rock->stopMove();
    }
  }
}

// ---------------------------------------------------------------------------
// Inputs: rotary encoder (interrupt driven) and two buttons
// ---------------------------------------------------------------------------
volatile int16_t encRaw = 0;
volatile uint8_t encState = 0;

void IRAM_ATTR encISR() {
  // Quadrature lookup: index = previous AB << 2 | current AB
  static const int8_t table[16] = {0,-1,1,0, 1,0,0,-1, -1,0,0,1, 0,1,-1,0};
  uint8_t ab = (gpio_get_level((gpio_num_t)PIN_ENC_A) << 1) | gpio_get_level((gpio_num_t)PIN_ENC_B);
  encState = ((encState << 2) | ab) & 0x0F;
  encRaw += table[encState];
}

// Returns whole detents turned since last call (KY-040 = 4 edges per detent).
int readEncoder() {
  noInterrupts();
  int16_t raw = encRaw;
  int detents = raw / 4;
  encRaw = raw - detents * 4;
  interrupts();
  return detents;
}

enum class BtnEvent : uint8_t { None, Short, Long };

struct Button {
  uint8_t  pin;
  bool     down = false;
  bool     longFired = false;
  uint32_t changedAt = 0;
  uint32_t downAt = 0;

  explicit Button(uint8_t p) : pin(p) {}

  BtnEvent update() {
    bool level = digitalRead(pin) == LOW;           // pressed = LOW
    uint32_t now = millis();
    if (level != down && now - changedAt > 25) {    // 25 ms debounce
      changedAt = now;
      down = level;
      if (down) { downAt = now; longFired = false; }
      else if (!longFired) return BtnEvent::Short;
    }
    if (down && !longFired && now - downAt > 800) {
      longFired = true;
      return BtnEvent::Long;
    }
    return BtnEvent::None;
  }
};

Button encBtn(PIN_ENC_SW);
Button mixBtn(PIN_MIX_BTN);

// ---------------------------------------------------------------------------
// User interface
// ---------------------------------------------------------------------------
enum class Ui : uint8_t { Status, Menu, Edit };
Ui  ui = Ui::Status;
int menuIdx = 0;
int menuTop = 0;
bool editDirty = false;
uint32_t lastInputAt = 0;

void runAction(Action a) {
  switch (a) {
    case Action::MixNow:   if (mode == Mode::Idle) startRun(false); ui = Ui::Status; break;
    case Action::Boost:    if (mode == Mode::Idle || mode == Mode::Session) {
                             if (mode == Mode::Session) { mode = Mode::Boost; modeStart = millis(); applyLiveChanges(); }
                             else startRun(true);
                           }
                           ui = Ui::Status; break;
    case Action::Stop:     if (mode == Mode::Session || mode == Mode::Boost) endRun();
                           else if (mode == Mode::Fault) { mode = Mode::Idle; idleStart = millis(); }
                           ui = Ui::Status; break;
    case Action::Defaults: setDefaults(); saveSettings(); applyLiveChanges(); break;
    case Action::Back:     ui = Ui::Status; break;
    default: break;
  }
}

void handleInputs() {
  int turn = readEncoder();
  BtnEvent eb = encBtn.update();
  BtnEvent mb = mixBtn.update();
  if (turn || eb != BtnEvent::None || mb != BtnEvent::None) lastInputAt = millis();

  // MIX button works from any screen
  if (mb == BtnEvent::Short) runAction(Action::MixNow);
  if (mb == BtnEvent::Long)  runAction(Action::Boost);

  switch (ui) {
    case Ui::Status:
      if (eb == BtnEvent::Short) {
        if (mode == Mode::Fault) runAction(Action::Stop);      // clear fault
        else { ui = Ui::Menu; menuIdx = 0; menuTop = 0; }
      }
      if (eb == BtnEvent::Long) {
        if (mode == Mode::Idle) startRun(false);
        else runAction(Action::Stop);
      }
      break;

    case Ui::Menu:
      if (turn) {
        menuIdx = constrain(menuIdx + turn, 0, MENU_LEN - 1);
        if (menuIdx < menuTop) menuTop = menuIdx;
        if (menuIdx > menuTop + 4) menuTop = menuIdx - 4;
      }
      if (eb == BtnEvent::Short) {
        if (menu[menuIdx].val) { ui = Ui::Edit; editDirty = false; }
        else runAction(menu[menuIdx].action);
      }
      if (eb == BtnEvent::Long) ui = Ui::Status;
      break;

    case Ui::Edit: {
      MenuItem& m = menu[menuIdx];
      if (turn) {
        int v = constrain(*m.val + turn * m.step, m.mn, m.mx);
        if (v != *m.val) { *m.val = v; editDirty = true; applyLiveChanges(); }
      }
      if (eb != BtnEvent::None) {
        if (editDirty) saveSettings();
        ui = Ui::Menu;
      }
      break;
    }
  }

  // Drop back to the status screen after 30 s without input
  if (ui != Ui::Status && millis() - lastInputAt > 30000) {
    if (ui == Ui::Edit && editDirty) saveSettings();
    ui = Ui::Status;
  }
}

const char* modeName() {
  switch (mode) {
    case Mode::Idle:    return "IDLE";
    case Mode::Session: return "MIXING";
    case Mode::Boost:   return "BOOST";
    case Mode::Parking: return "PARKING";
    case Mode::Fault:   return "FAULT";
  }
  return "?";
}

const char* phaseName() {
  switch (phase) {
    case Phase::RunFwd: return "Forward";
    case Phase::RunRev: return "Reverse";
    case Phase::StopA: case Phase::StopB: return "Slowing";
    default: return "Pause";
  }
}

// mm:ss or h:mm text for a duration in ms
void fmtDur(char* out, size_t n, uint32_t ms) {
  uint32_t s = ms / 1000;
  if (s >= 3600) snprintf(out, n, "%luh%02lum", (unsigned long)(s / 3600), (unsigned long)((s % 3600) / 60));
  else           snprintf(out, n, "%lu:%02lu", (unsigned long)(s / 60), (unsigned long)(s % 60));
}

void drawStatus() {
  char line[32], t[12];
  uint32_t now = millis();
  oled.setFont(u8g2_font_7x13B_tf);
  oled.drawStr(0, 12, modeName());
  oled.setFont(u8g2_font_6x10_tf);
  snprintf(line, sizeof line, "%drpm %s", activeRpm(), cfg.rockOn ? "rock" : "");
  oled.drawStr(128 - oled.getStrWidth(line), 12, line);

  if (mode == Mode::Session || mode == Mode::Boost) {
    uint32_t phaseLen = (phase == Phase::RunFwd || phase == Phase::RunRev) ? cfg.runSec * 1000UL
                      : (phase == Phase::PauseA || phase == Phase::PauseB) ? cfg.pauseSec * 1000UL : 0;
    uint32_t inPhase = now - phaseStart;
    fmtDur(t, sizeof t, phaseLen > inPhase ? phaseLen - inPhase : 0);
    snprintf(line, sizeof line, "%-8s %s", phaseName(), t);
    oled.drawStr(0, 28, line);
    uint32_t limit = (mode == Mode::Boost) ? cfg.boostSec * 1000UL : cfg.sessionMin * 60000UL;
    if (limit == 0) snprintf(line, sizeof line, "Continuous");
    else { fmtDur(t, sizeof t, limit > now - modeStart ? limit - (now - modeStart) : 0);
           snprintf(line, sizeof line, "Ends in  %s", t); }
    oled.drawStr(0, 40, line);
  } else if (mode == Mode::Idle) {
    if (cfg.intervalMin == 0) snprintf(line, sizeof line, "Manual only");
    else { uint32_t iv = cfg.intervalMin * 60000UL, el = now - idleStart;
           fmtDur(t, sizeof t, iv > el ? iv - el : 0);
           snprintf(line, sizeof line, "Next in  %s", t); }
    oled.drawStr(0, 28, line);
  } else if (mode == Mode::Fault) {
    oled.drawStr(0, 28, faultMsg);
    oled.drawStr(0, 40, "Click to clear");
  } else {
    oled.drawStr(0, 28, "Parking tip-up...");
  }

  snprintf(line, sizeof line, "SG:%d %s%s", lastSG, rollDrvOk ? "" : "ROLL? ", rockDrvOk ? "" : "ROCK?");
  oled.drawStr(0, 52, line);
  oled.drawStr(0, 63, "Click=menu Hold=go/stop");
}

void drawMenu() {
  oled.setFont(u8g2_font_6x10_tf);
  for (int row = 0; row < 5 && menuTop + row < MENU_LEN; row++) {
    int i = menuTop + row;
    int y = 11 + row * 12;
    bool sel = (i == menuIdx);
    if (sel) { oled.drawBox(0, y - 9, 128, 11); oled.setDrawColor(0); }
    oled.drawStr(2, y, menu[i].label);
    if (menu[i].val) {
      char v[16];
      if (menu[i].mx == 1) snprintf(v, sizeof v, "%s", *menu[i].val ? "On" : "Off");
      else snprintf(v, sizeof v, "%d%s", *menu[i].val, menu[i].unit);
      int x = 126 - oled.getStrWidth(v);
      if (sel && ui == Ui::Edit) oled.drawStr(x - 8, y, ">");
      oled.drawStr(x, y, v);
    }
    oled.setDrawColor(1);
  }
}

void drawScreen() {
  static uint32_t last = 0;
  if (millis() - last < 200) return;     // 5 fps is plenty and keeps I2C quiet
  last = millis();
  oled.clearBuffer();
  if (ui == Ui::Status) drawStatus(); else drawMenu();
  oled.sendBuffer();
}

// ---------------------------------------------------------------------------
// Optional Wi-Fi page: join "PaintRoller" and browse to http://192.168.4.1
// ---------------------------------------------------------------------------
#if ENABLE_WIFI
WebServer server(80);

void handleRoot() {
  String h = F("<!doctype html><html><head><meta name=viewport content='width=device-width'>"
               "<title>Paint Roller</title><style>body{font-family:sans-serif;max-width:420px;margin:auto;padding:12px}"
               "label{display:flex;justify-content:space-between;margin:6px 0}input{width:90px}"
               "a.b{display:inline-block;padding:8px 14px;margin:4px;background:#333;color:#fff;border-radius:6px;text-decoration:none}"
               "</style></head><body><h2>Paint Roller</h2>");
  h += "<p>Status: <b>"; h += modeName(); h += "</b></p>";
  h += F("<p><a class=b href='/mix'>Mix now</a><a class=b href='/boost'>Boost</a><a class=b href='/stop'>Stop</a></p>"
         "<form action='/set'>");
  for (int i = 0; i < MENU_LEN; i++) {
    if (!menu[i].val) continue;
    h += "<label>"; h += menu[i].label; h += " ("; h += menu[i].unit; h += ")";
    h += "<input type=number name='"; h += menu[i].key;
    h += "' min="; h += menu[i].mn; h += " max="; h += menu[i].mx;
    h += " value="; h += *menu[i].val; h += "></label>";
  }
  h += F("<p><button>Save</button></p></form></body></html>");
  server.send(200, "text/html", h);
}

void redirectHome() { server.sendHeader("Location", "/"); server.send(303); }

void handleSet() {
  bool changed = false;
  for (int i = 0; i < MENU_LEN; i++) {
    if (!menu[i].val || !server.hasArg(menu[i].key)) continue;
    int v = constrain(server.arg(menu[i].key).toInt(), menu[i].mn, menu[i].mx);
    if (v != *menu[i].val) { *menu[i].val = v; changed = true; }
  }
  if (changed) { saveSettings(); applyLiveChanges(); }
  redirectHome();
}

void setupWifi() {
  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASS);
  server.on("/", handleRoot);
  server.on("/set", handleSet);
  server.on("/mix",   [] { runAction(Action::MixNow); redirectHome(); });
  server.on("/boost", [] { runAction(Action::Boost);  redirectHome(); });
  server.on("/stop",  [] { runAction(Action::Stop);   redirectHome(); });
  server.begin();
}
#endif

// ---------------------------------------------------------------------------
// Setup and loop
// ---------------------------------------------------------------------------
bool initDriver(TMC2209Stepper& d, uint16_t mA) {
  d.begin();
  d.pdn_disable(true);        // PDN_UART pin is used for UART, not power-down
  d.mstep_reg_select(true);   // microsteps from register, not MS pins (those set the address)
  d.I_scale_analog(false);    // current from register
  d.toff(4);
  d.blank_time(24);
  d.rms_current(mA);
  d.microsteps(MICROSTEPS);
  d.intpol(true);             // interpolate to 256 microsteps: smoother, quieter
  d.en_spreadCycle(false);    // StealthChop = near silent
  d.pwm_autoscale(true);
  d.pwm_autograd(true);
  d.TCOOLTHRS(0xFFFFF);       // allow StallGuard readings at low speed
  d.SGTHRS(0);                // we poll SG_RESULT instead of using DIAG
  return d.test_connection() == 0;
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_LED, OUTPUT);
  pinMode(PIN_ENC_A, INPUT_PULLUP);
  pinMode(PIN_ENC_B, INPUT_PULLUP);
  pinMode(PIN_ENC_SW, INPUT_PULLUP);
  pinMode(PIN_MIX_BTN, INPUT_PULLUP);
  pinMode(PIN_HOME_SW, INPUT);              // GPIO34 has no internal pull-up
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_A), encISR, CHANGE);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_B), encISR, CHANGE);

  loadSettings();

  Wire.begin(PIN_SDA, PIN_SCL);
  oled.begin();
  oled.clearBuffer();
  oled.setFont(u8g2_font_6x10_tf);
  oled.drawStr(0, 20, "Paint Roller v1");
  oled.drawStr(0, 36, "Starting...");
  oled.sendBuffer();

  Serial2.begin(115200, SERIAL_8N1, PIN_TMC_RX, PIN_TMC_TX);
  rollDrvOk = initDriver(drvRoll, cfg.rollmA);
  rockDrvOk = initDriver(drvRock, cfg.rockmA);
  Serial.printf("TMC roll %s, rock %s\n", rollDrvOk ? "OK" : "NOT FOUND", rockDrvOk ? "OK" : "NOT FOUND");

  engine.init();
  roll = engine.stepperConnectToPin(PIN_ROLL_STEP);
  rock = engine.stepperConnectToPin(PIN_ROCK_STEP);
  if (!roll || !rock) { Serial.println("Stepper init failed"); while (true) delay(1000); }
  roll->setDirectionPin(PIN_ROLL_DIR, !ROLL_DIR_INVERT);
  rock->setDirectionPin(PIN_ROCK_DIR, !ROCK_DIR_INVERT);
  roll->setEnablePin(PIN_ROLL_EN, true);    // true = EN is active LOW
  rock->setEnablePin(PIN_ROCK_EN, true);
  roll->setAutoEnable(false);
  rock->setAutoEnable(false);
  roll->setAcceleration(ROLL_ACCEL);
  rock->setAcceleration(ROCK_ACCEL);
  motorsOff();

#if ENABLE_WIFI
  setupWifi();
#endif

  // Park the cradle tip-up on power-up, then wait for the first interval.
  mode = Mode::Parking;
  modeStart = millis();
  if (HAS_HOME_SWITCH && cfg.rockOn && !homeTriggered()) rock->enableOutputs();
  idleStart = millis();
  lastInputAt = millis();
}

void loop() {
  handleInputs();
  updateMotion();
  drawScreen();
#if ENABLE_WIFI
  server.handleClient();
#endif
}
