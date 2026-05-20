# Mobile APK Fixes: Landscape + Real Joystick

Two separate bugs identified from code inspection.

---

## Bug A — Portrait Mode

**Root cause:** `project.godot` line 27:
```
window/handheld/orientation=1
```
Value `1` = **portrait**. For forced landscape, it should be `4` (`sensor_landscape` — handles both normal and reversed landscape orientations, safe for all Android devices).

**Fix:** Change `orientation=1` → `orientation=4` in `project.godot`.

---

## Bug B — Joystick Is Functionally Broken (Two Nested Issues)

### Issue B1: Wrong input method (`gui_input` on Android)

`touch_controls.gd` connects to `base.gui_input` (the `JoystickBase` Panel's signal). On Android, `gui_input` only fires while the finger remains *over* that specific control's bounds. **The moment you drag past the edge of the 96×96 joystick base, all drag events stop arriving** — the joystick freezes. This makes it feel "fake."

**Fix:** Replace `base.gui_input.connect(...)` with the global `_input()` override, which receives all screen touch/drag events regardless of where the finger is.

### Issue B2: Player never actually moves from joystick input

Even if the touch events were received, the player would still not move. In `player.gd`:

```gdscript
# Line 82 — direction starts from UI KEYS, not joystick actions
var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
    direction.y = 0   # ← zeroes out y from an already-zero direction
```

`get_vector("ui_left", ...)` returns `(0,0)` on mobile (no keyboard). The joystick's `move_left/right/up/down` presses only control which axis is zeroed out — but since direction is already `(0,0)`, the player stands still.

**Fix:** Rewrite `player.gd`'s direction logic to check `move_*` actions first and use their combined vector as the actual movement direction, falling back to `ui_*` keyboard only when no joystick input is active.

---

## Proposed Changes

### [MODIFY] `project.godot`
- Line 27: `window/handheld/orientation=1` → `window/handheld/orientation=4`

---

### [MODIFY] `scripts/touch_controls.gd`
Full rewrite:
- Replace `base.gui_input.connect(...)` in `_ready()` with `_input()` override
- Detect touch-start anywhere in the **left half** of the screen (generous activation zone)
- Track the touch by index; update knob from global position → local offset from base center
- In `_process()`: properly call `Input.action_press("move_left")` (no second arg) when direction exceeds threshold, and `Input.action_release()` for the opposite axes

---

### [MODIFY] `scripts/player.gd`
- Replace the current complex direction logic with two branches:
  1. **Joystick branch**: if any `move_*` action is pressed, build `direction` from those four actions directly, then snap to 4-directional movement
  2. **Keyboard branch**: fallback to `get_vector("ui_left", "ui_right", "ui_up", "ui_down")` snapped to 4-directional

---

### [MODIFY] `scenes/ui/game_ui.tscn` *(visual polish only)*
- Give `JoystickBase` and `JoystickKnob` styled appearances (circular, semi-transparent) so the joystick is clearly visible on device
- Slightly enlarge the joystick zone for easier thumb reach

---

## Verification Plan

1. Run on desktop: arrow keys still move the player (keyboard branch untouched)
2. In Godot editor's **Remote** inspector or Android emulator: tap and drag left side of screen — player moves; drag beyond joystick bounds — player keeps moving until finger is lifted
3. Export APK and install: game launches in **landscape**, joystick is visible bottom-left, drag to move works
