# Fix Android Export: Orientation + Joystick

## Summary

Two issues to fix for the APK export:
1. **Portrait mode** — the game renders in portrait on Android instead of forced landscape.
2. **Broken virtual joystick** — the existing `touch_controls.gd` joystick listens on `gui_input` of the `JoystickBase` Panel, but in Godot 4 on Android the `JoystickZone` + `JoystickBase` never actually receive touch events because the root `TouchLayer` has `mouse_filter = MOUSE_FILTER_IGNORE` and the `JoystickBase` is a Panel with no explicit filter set, so touch events fall through or get eaten by the scene tree before reaching it.

---

## Diagnosis

### A) Orientation

In `project.godot`:
```
window/handheld/orientation=1
```
`1` = **Portrait** in Godot 4 (`SCREEN_PORTRAIT`). Landscape is `2` (`SCREEN_LANDSCAPE`).

In `export_presets.cfg` there is **no** `screen/orientation` key, so it inherits the project default which is portrait.

### B) Joystick Bug

In `touch_controls.gd`, the joystick listens via:
```gdscript
base.gui_input.connect(_on_base_input)
```
`gui_input` on a `Panel` node only fires if:
- The Panel's `mouse_filter` is **Stop** (0) or **Pass** (1), AND
- Nothing above it in the tree is consuming the event first.

The `TouchLayer` control has `mouse_filter = 2` (IGNORE) which is correct. But looking at the scene: `JoystickBase` is a `Panel` — its default mouse_filter is **Stop** which should be fine in theory. 

The **real problem** is that `gui_input` only receives `InputEventMouseButton`/`InputEventMouseMotion` on desktop; on **mobile/Android**, touch events arrive as `InputEventScreenTouch` and `InputEventScreenDrag` and these are **not** routed through `gui_input` on regular `Control`/`Panel` nodes unless you enable **emulate mouse from touch** or handle `_input`/`_unhandled_input` instead.

So the joystick *appears* to exist visually but **never receives any input on mobile** since it relies on `gui_input` for screen touch events.

**Solution**: Rewrite `touch_controls.gd` to use `_input()` (or `_unhandled_input()`) at the scene level and do manual hit-testing against the joystick base rect, which is the standard, reliable way to handle virtual joysticks in Godot 4 on mobile.

---

## Proposed Changes

### 1. Fix Orientation

#### [MODIFY] [project.godot](file:///home/row-huh/rpg/project.godot)
Change `window/handheld/orientation=1` → `window/handheld/orientation=2` (Landscape).

#### [MODIFY] [export_presets.cfg](file:///home/row-huh/rpg/export_presets.cfg)
Add explicit `screen/orientation=2` under `[preset.0.options]` to lock landscape in the APK manifest.

---

### 2. Rewrite the Virtual Joystick

#### [MODIFY] [touch_controls.gd](file:///home/row-huh/rpg/scripts/touch_controls.gd)

Complete rewrite using `_input()` + manual hit-test approach:

- Override `_input(event)` on the `TouchLayer` Control (which already spans the full screen).
- On `InputEventScreenTouch` pressed: check if the touch position falls inside the `JoystickBase` global rect. If yes, claim that touch index and begin dragging.
- On `InputEventScreenDrag`: if it's our claimed index, update knob position.
- On `InputEventScreenTouch` released: reset.
- Inject `move_*` input actions in `_process` exactly as before.
- Visually draw an outer ring + inner knob using `draw_*` calls or keep the existing Panel nodes (just fix the input handling).

The `TalkTouchButton` in the scene (Button node) uses a separate mechanism and already works fine via its `pressed` signal — **no changes needed there**.

---

## Scene Changes

No `.tscn` edits required. The rewrite is entirely in the script.

> [!IMPORTANT]
> After these changes, the joystick will receive touch events via `_input()` at the `TouchLayer` level, bypassing the broken `gui_input` + Panel chain. This is the correct Godot 4 mobile input pattern.

---

## Verification Plan

1. Export APK and install on device → confirm landscape forced orientation.
2. Tap-and-drag the joystick zone → player should move in the correct direction.
3. Confirm the `TalkTouchButton` still fires the interact action.
4. Confirm joystick hides properly during dialogue/intro (existing `game_ui.gd` logic already handles this via `joystick_zone.visible`).
