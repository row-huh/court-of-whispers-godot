# Dynamic Music and Dialogue Banners Plan

This plan outlines the client-side implementation of music state changes at key day transitions, along with custom interactive banners.

---

## Technical Architecture & Flow

### 1. Music Transition Schedule

| Day | Event | Music Action | Audio Asset |
| :--- | :--- | :--- | :--- |
| **Day 1** | Final Message Submitted | **Stop** | `without_me_medieval.mp3` |
| **Night 1** | End of Day Summary Appears | **Start** | `never_gonna_give_you_up.mp3` (fallback: default) |
| **Day 4** | Final Message Submitted | **Stop** | `never_gonna_give_you_up.mp3` |
| **Night 4** | End of Day Summary Appears | **Start** | `reigen.mp3` (fallback: `gogoreigen.mp3`) |

### 2. Custom Interactive Banners

To prevent modifying `.tscn` files and ensure a reliable layout, we will programmatically construct the premium fantasy RPG styled dialogs inside `game_ui.gd`:

*   **Night 1 to Day 2 Transition (Rickroll Banner)**:
    *   Triggered when clicking "Dawn breaks" on Night 1.
    *   Displays: `"Never gonna give you up, Never gonna let you down"`
    *   Two Buttons: `" Oh FFS"` and `"Never gonna run around and dessert you!"`
    *   Clicking either dismisses the banner and advances the day.
*   **Night 4 to Day 5 Transition (Warning Banner)**:
    *   Triggered when clicking "Dawn breaks" on Night 4.
    *   Displays: `"You have only 2 more days!"`
    *   One Button: `"Continue"`
    *   Clicking dismisses the banner and advances the day.

---

## User Review Required

### Backend Requirements:
> [!NOTE]
> **No backend changes are required for this task.**
> Music playback and banner overlays are completely client-side. The local Godot `GameManager` already has the necessary state variables (`day`, `turns_left`, and `pending_night`) pushed from `/api/state` to drive all triggers natively.

### Robust Fail-safes:
> [!TIP]
> If `never_gonna_give_you_up.mp3` or `reigen.mp3` are missing from the game directory at runtime, our code will gracefully fall back to existing music files (`without_me_medieval.mp3` and `gogoreigen.mp3`) to avoid runtime crashes.

---

## Proposed Changes

### Godot Client (Audio & Dialogs)

#### [MODIFY] [game_manager.gd](file:///home/row-huh/rpg/autoload/game_manager.gd)
- Add global signal `signal music_stop_requested`.

#### [MODIFY] [dialogue_controller.gd](file:///home/row-huh/rpg/scripts/dialogue_controller.gd)
- In `_on_input_submitted(text)`, if `GameManager.turns_left == 1` and `GameManager.day` is `1` or `4`, emit `GameManager.music_stop_requested`.

#### [MODIFY] [game_ui.gd](file:///home/row-huh/rpg/scripts/game_ui.gd)
- Add properties `var _night_song_triggered_day: int = -1` and `var _active_banner: PanelContainer = null`.
- Connect `GameManager.music_stop_requested` to custom `stop_song()`.
- Implement `play_song(song_name: String)` and `stop_song()` with asset verification.
- Implement `_show_custom_banner(text: String, buttons: Array[String], callback: Callable)` programmatically.
- In `_populate_night_modal()`, trigger the relevant song if the current day has not been triggered yet.
- In `_on_night_close_pressed()`, instead of closing immediately:
  - If `day == 1`, show the Rickroll banner.
  - If `day == 4`, show the warning banner.
  - Otherwise, close normally.

---

## Verification Plan

### Manual Verification Steps
1. Play Day 1, submit the 5th message. Verify that music stops immediately.
2. Verify that `NightModal` fades in, and `never_gonna_give_you_up.mp3` plays immediately.
3. Click "Dawn breaks". Verify that the Rickroll dialogue banner overlays perfectly with its two buttons.
4. Click either button, verify that the banner closes and Day 2 begins.
5. Repeat for Day 4, verifying the music stops, starts `reigen.mp3`, and displays "You have only 2 more days!" on close.
