# UI Improvements — Day Cascade, Night Summary, Conversation Toasts

## Overview

Three distinct features to implement:
1. **Quest cascade on day change** — checklist auto-updates; day header animates
2. **Night summary redesign** — clean dark modal showing NPC whispers + per-metric delta rows
3. **Post-conversation toast system** — 3 notification chips slide down from the top after every dialogue close

---

## Feature 1 — Quest Checklist Cascades on Day Change

### Problem
The `Your Path` checklist re-renders on every `state_changed` already, but the **day label** at the top of the drawer doesn't pulse/animate when the day increments, and the checklist text stays the same color for completed and pending tasks.

### Changes

#### [MODIFY] `game_hud.gd`
- Detect when `GameManager.day` changes between `_refresh()` calls; if so, pulse the `DayLabel` with a short gold flash tween.
- Completed quest items (`●`) rendered in a brighter gold `#d4a648`; pending items in dim stone `#6b5f52`.

---

## Feature 2 — Night Summary Redesign

### Problem
The `NightModal` is a plain `PanelContainer` with a `RichTextLabel` and a basic button. It shows NPC whisper text but **no metric summary** — the player can't see what changed (proof+8, Alaric trust -3, etc.).

### Plan

**Store "day snapshot" before night runs** — In `GameManager`, record a `_day_start_snapshot` dict at the start of each turn sequence. When night closes, compute deltas.

#### [MODIFY] `game_manager.gd`
- Add `var _pre_night_snapshot: Dictionary = {}` 
- In `_run_night_phase()`, snapshot current values before calling the night API
- Expose `func get_day_deltas() -> Dictionary` that computes the diff vs snapshot

#### [MODIFY] `game_ui.tscn` — NightModal section
Replace the current `220×320` centered box with a wider dark panel (`480×520`) containing:
```
┌─────────────────────────────────────────┐
│  ✦  Night Falls — Day 1 Summary  ✦     │
├─────────────────────────────────────────┤
│  WHISPERS IN THE COURT                  │
│  [scrollable NPC exchange list]         │
├─────────────────────────────────────────┤
│  WHAT SHIFTED TODAY                     │
│  Sir Alaric's Trust     30 → 38  [+8]  │
│  Bishop's Proof          0 → 0   [±0]  │
│  Suspicion               0 → 4   [+4]  │
├─────────────────────────────────────────┤
│          [ Dawn breaks → ]              │
└─────────────────────────────────────────┘
```
- Positive deltas: gold `#d4a648`
- Negative deltas: red `#c0392b`
- Zero: dim stone

#### [MODIFY] `game_ui.gd` — `_populate_night_modal()`
- Pull `GameManager.get_day_deltas()` and append a styled metrics section to the night log RichTextLabel (or a separate Label node).

---

## Feature 3 — Post-Conversation Toast Notifications

After every dialogue `close_dialogue()`, show 2–3 small chips sliding down from the top of the screen with the outcome of that conversation.

### Toast Types (always shown after every convo close)
| Chip | Icon | Example |
|---|---|---|
| **Gossip** | `〰` | `Gossip +3` |
| **Trust** | `♥` | `Sir Alaric ▲ +5` or `Mira ▼ -2` |
| **Fear** | `⚠` | `Edran fear ▲ +4` (priest only) |

### Architecture

#### [NEW] `scenes/ui/toast_notification.tscn`
A small `PanelContainer` (`280×40`) with:
- Left: icon label (font size 16)
- Middle: text label (font size 13)
- Right: optional value label (bold, colored)

Uses `StyleBoxFlat` with dark bg + gold left border (4px).

#### [NEW] `scripts/toast_manager.gd`
Autoload-style node (added to `GameUI`'s scene tree):
- `func show_toasts(delta: Dictionary, agent_id: String)` — builds 1–3 Toast nodes
- Toasts slide in from `y = -60` to `y = 72` (below DrawerToggleButton), staggered 100ms apart
- Auto-dismiss after 2.5s with a fade-out tween
- Maximum 4 toasts visible at once; older ones slide up

#### [MODIFY] `dialogue_controller.gd`
- In `_on_agent_delta_ready()`, after `GameManager.apply_delta()`, call `ToastManager.show_toasts(delta, agent_id)` (via `get_node_or_null("%ToastManager")`)

#### [MODIFY] `game_ui.tscn`
- Add `ToastManager` node (with `%ToastManager` unique name) as a child of `GameUI`

---

## Verification Plan

### Manual
1. Start a game, open drawer — checklist shows `○` for all items
2. Talk to Mira until `citizen_offered_blackmail = true` — checklist item 1 turns gold `●`
3. End the day — night modal shows metric deltas styled correctly
4. After every NPC conversation close — toasts slide in from top, show correct values, auto-dismiss

### Automated
- None (UI-only changes; no new GDScript logic paths to unit-test)

---

## Open Questions

> [!IMPORTANT]
> **Toast position** — The toasts will appear at `y ≈ 72px` (just below the ☰ button). If the drawer is open, toasts appear over it. Is that OK, or should they always appear on the opposite (right) side of the screen?

> [!NOTE]
> The **NightModal snapshot** approach snapshots values *at the start of the night phase*, not at the start of the day. So the deltas reflect only what the *night NPC whispers* changed, not the full day's trust movement. Should the snapshot happen at **day start** instead to show the full day's movement?
