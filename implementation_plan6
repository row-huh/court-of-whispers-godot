# Implementation Plan - Dialogue Session Cursor Hiding

We will update the mouse cursor visibility flow to ensure that the cursor remains completely hidden during active dialogue sessions with any of the 4 agents. Keyboard inputs (Enter/Escape) can be fully used to advance lines, type responses, and cancel/leave conversations. The cursor will only reappear once the conversation is completely finished/closed.

## User Review Required

> [!NOTE]
> All dialogue actions (Continue, Speak, Skip, Cancel/Leave) support native keyboard binds:
> - **Enter / Space (ui_accept)**: Skip typing typewriter, click Continue, submit whispered text.
> - **Escape (ui_cancel)**: Cancel input modal, leave/close conversation.

No external configuration changes or breaking changes are introduced.

## Proposed Changes

We will modify two script files in the Godot project:

### 1. Dialogue Controller

#### [MODIFY] [dialogue_controller.gd](file:///d:/court-of-whispers-godot/scripts/dialogue_controller.gd)
- **Hiding during the entire session**: Hide the mouse at the start of dialogue (`_on_dialogue_open`) and keep it hidden during the entire active conversation.
- **Remove cursor showing triggers**: Remove the mouse cursor visibility triggers from:
  - `_on_line_finished()`
  - `_on_continue_pressed()`
  - `_on_input_cancelled()`
- **Show on dialogue end/leave**: Set `Input.mouse_mode = Input.MOUSE_MODE_VISIBLE` in `_on_close()` and `_on_dialogue_closed()` to restore the cursor when the conversation is completely closed.

---

### 2. Player Input Modal

#### [MODIFY] [player_input_modal.gd](file:///d:/court-of-whispers-godot/scripts/player_input_modal.gd)
- **Remove cursor show trigger**: Remove the cursor visibility trigger in `open_modal()` to keep the cursor hidden while the player is typing their whispered text.

## Verification Plan

### Automated/Engine Verification
- Run the Godot project locally and observe:
  1. Click "Talk" with the cursor -> cursor immediately disappears.
  2. Dialogues typewriter / complete -> cursor remains completely hidden.
  3. Enter input modal / type -> cursor remains hidden.
  4. Press Escape to close/leave conversation -> conversation closes, and the cursor immediately becomes visible again on the game screen.
