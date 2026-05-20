# Live HUD State Sync from Backend

## Problem

The HUD values (trust bars, proof, suspicion) are stored in `GameManager` on the Godot side, but they are **only updated via `apply_delta`** after each LLM response. If the player hasn't spoken recently, or the backend changes agent state via the night phase, the HUD won't reflect those changes until `state_changed` fires.

However, the real issue you're seeing is different — the `_refresh()` in `game_hud.gd` is gated by `if not visible: return`. Since the drawer starts *closed* (off-screen), `visible` is `false` on the `GameHUD` node, so **_refresh never fires**. Additionally, when the HUD slides in/out by changing `position.x`, `visible` never changes — meaning `_refresh` never gets called.

## Root Cause

1. `_refresh()` returns early when `hud.visible == false`, but the drawer uses *position animation* not visibility toggling — so `visible` is always `false` when `status != "playing"`, and once set to `true` when playing starts, it stays `true` but `_refresh` was never called at the right moment.
2. The `%DrawerToggleButton` `unique_name_in_owner` works, but the button needs to correctly sit above the HUD layer in the scene tree (already fixed).

## Proposed Changes

### Fix 1: Remove visibility guard in `_refresh`

#### [MODIFY] game_hud.gd
- Remove the `if not visible: return` guard — `_refresh` should always update the data. The `GameManager.state_changed` signal fires reliably when `apply_delta` is called.

### Fix 2: Add a `/api/state` GET endpoint in the backend

#### [NEW] `src/routes/api/state.ts`
- Returns the current world state (trust values, proof, suspicion, flags) from a in-memory store.
- The backend currently doesn't persist state between requests — each call to `/api/agent` is stateless, receiving context from the Godot client.
- Since the backend is stateless (Godot is the source of truth), this endpoint isn't needed. The correct fix is in Godot.

### Fix 3: Ensure `_refresh` fires when drawer opens

#### [MODIFY] `game_ui.gd`
- In `_on_drawer_toggle()`, after tweening, call `hud._refresh()` to force a UI update when the drawer is opened.

### Fix 4: Ensure `_refresh` fires on state changes while playing

The `_refresh()` is already connected to `GameManager.state_changed` in `game_hud.gd._ready()`. The only missing piece is the visibility guard causing it to skip.

## Summary of Changes

| File | Change |
|---|---|
| `game_hud.gd` | Remove early-return guard `if not visible` |
| `game_ui.gd` | Call `hud._refresh()` after drawer tween completes |

These are minimal, targeted fixes that will make the values live and responsive.
