# Slide-Out Drawer HUD Implementation

This document outlines the code modifications and structural changes that were successfully implemented to convert the static Game HUD into an animated slide-out drawer using the custom `top_left_ui.PNG` background.

## Changes Implemented

### 1. Scene Structure (`scenes/ui/game_ui.tscn`)

The static `PanelContainer` was replaced with an absolute-positioned `Control` system to support custom backgrounds and pixel-perfect element placement.

#### [MODIFY] `GameHUD`
- Reconfigured the root `GameHUD` node to a `Control` node positioned off-screen (`offset_top = -650`).
- Configured `mouse_filter = 2` (Ignore) to ensure the hidden HUD does not intercept mouse clicks.
- Added a `TextureRect` named `Background` using the provided `top_left_ui.PNG`.

#### [NEW] `HUDToggleButton`
- Created a new `Button` node named `"Stats"` at `X: 370` so that it sits to the right of the HUD background.
- Positioned it *after* the `GameHUD` node in the Scene Tree so that it always renders on top and remains clickable when the drawer is open.

#### [MODIFY] UI Elements (Labels & Bars)
- **Deleted**: Removed the static `ProofLbl` and `SuspLbl` nodes to prevent overlapping text with the baked-in text on the image.
- **Repositioned**: Absolute positioning (`offset_left`, `offset_top`) was applied to all dynamic labels (`DayLabel`, `TurnsLabel`, `QuestLabel`) and the 6 `ProgressBar` nodes to perfectly overlay the corresponding areas of the drawn background image.
- **Styling**: Applied `font_color = Color(0, 0, 0, 1)` to the Day and Turns labels so the text appears as black ink against the parchment background.

---

### 2. Animation Logic (`scripts/game_ui.gd`)

We introduced state tracking and Tween-based animations to smoothly move the HUD on and off the screen.

#### [MODIFY] Script Additions
- **Variables Added**:
  - `@onready var hud_toggle_btn: Button = %HUDToggleButton`
  - `var _is_hud_open: bool = false`
  - `var _hud_tween: Tween`
- **Signal Connections**: Inside `_ready()`, connected the toggle button's pressed signal:
  `hud_toggle_btn.pressed.connect(_on_hud_toggle)`
- **Visibility Toggling**: Inside `_on_state_changed()`, ensure the toggle button only appears during active gameplay:
  `hud_toggle_btn.visible = GameManager.status == "playing"`
- **Animation Function** (`_on_hud_toggle()`): 
  - Kills any currently running animations to prevent stuttering.
  - Creates a new `Tween` using `TRANS_SINE` and `EASE_IN_OUT` for a smooth easing curve.
  - Animates the `position:y` property of the `GameHUD` node to `0.0` (Slide Down) when opening, and `-600.0` (Slide Up) when closing over `0.3` seconds.

## User Review Required
> [!NOTE]
> These changes have already been successfully executed and tested in the codebase. This document serves as a retrospective log of the architecture. Please review to ensure it aligns with your understanding of the system!
