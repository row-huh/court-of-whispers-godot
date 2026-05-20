# Strikethrough Task List Implementation Plan

We want to enhance the RPG side drawer HUD so that objectives are clearly crossed out (strikethrough effect) and visually muted once completed. This plan details how to implement this in the Godot client and specifies the options for backend support.

---

## User Review Required

We have proposed two architectures for this feature:
1. **Option A: Static/Hardcoded Quests (Client-Side Logic, Zero Backend Changes)**
   - Leverages the existing server-side game state fields (`citizenOfferedBlackmail`, `priestSpilledDirt`, `citizenEndorsedCommander`, `status`).
   - Requires **no changes** to the backend API or schema.
2. **Option B: Dynamic/AI-Generated Tasks (Flexible, Server-Side AI Driven)**
   - Allows the backend AI to dynamically generate, assign, and mark tasks complete based on dialogue.
   - Requires introducing a new `tasks` array field to the backend `GameState` schema.

> [!IMPORTANT]
> Please review both options and let us know which path fits your gameplay vision. Option A is faster and works immediately; Option B is more powerful and supports dynamic AI-driven quests.

---

## Open Questions

> [!IMPORTANT]
> 1. **Option A vs. Option B**: Do you prefer sticking to the existing hardcoded set of 4 quests (Option A), or would you like to transition to a dynamic, LLM-generated task checklist (Option B)?
> 2. **Coup Quest Trigger (Quest 4)**: Currently, the fourth quest ("Convince the Commander to perform the coup") is hardcoded to `false` in Godot. Should it be checked off as soon as `GameManager.status == "won"`?

---

## Proposed Changes

### Godot Client (HUD Formatting)

To implement the strikethrough visual effect, we will utilize Godot's `RichTextLabel` BBCode `[s]...[/s]` (strikethrough) tag and apply a muted color to completed tasks.

#### [MODIFY] [game_hud.gd](file:///home/row-huh/rpg/scripts/game_hud.gd)
- Update `_format_quest(text: String, is_done: bool)`:
  - If `is_done` is `true`, return the text enclosed in `[s]...[/s]` strikethrough tags and style it with a muted, darker gray-brown color (`#6b5f52` or `#8a7d6e`) to visually push it to the background.
  - If `is_done` is `false`, return it with active gold text and empty bullet (`○`).
- Update `_refresh()` quest assignment:
  - Map Quest 4 (`Convince the Commander to perform the coup`) completion to `GameManager.status == "won"` instead of hardcoded `false`.

```gdscript
# Example updated quest format function
func _format_quest(text: String, is_done: bool) -> String:
	if is_done:
		return "  [color=#7c6f62][s]● %s[/s][/color]" % text
	return "  [color=#d4a648]○ %s[/color]" % text
```

---

### Option A: Static Quests (No Backend Changes)

If we proceed with the current hardcoded objectives, the backend already provides all the required fields in `GET /api/state`:
- `citizenOfferedBlackmail` (for Quest 1)
- `priestSpilledDirt` (for Quest 2)
- `citizenEndorsedCommander` (for Quest 3)
- `status` (for Quest 4 - when set to `"won"`)

No backend modifications are necessary. We only need to adjust the Godot UI layer in `game_hud.gd`.

---

### Option B: Dynamic/AI-Generated Tasks (Requires Backend Changes)

If you want the AI/backend to dynamically generate tasks (e.g. "Find out about the priest's secret", "Talk to Alaric in the fields"), the backend needs to store and synchronize a list of tasks.

#### Backend Schema Changes

1. **`court-of-whispers/src/routes/api/state.ts`**:
   - Add a `tasks` array field to `GameState` interface:
     ```typescript
     export interface Task {
       id: string;
       description: string;
       isCompleted: boolean;
     }

     export interface GameState {
       // ... existing fields ...
       tasks: Task[];
     }
     ```
   - Update `DEFAULT_STATE` to initialize default tasks:
     ```typescript
     tasks: [
       { id: "leverage", description: "Earn Mira's faith — she offers leverage on the priest", isCompleted: false },
       { id: "priest_dirt", description: "Press Father Edran for palace dirt", isCompleted: false },
       { id: "endorsement", description: "Bring the dirt back to Mira — she endorses you", isCompleted: false },
       { id: "coup", description: "Convince the Commander to perform the coup", isCompleted: false }
     ]
     ```

2. **Backend LLM Agent Actions**:
   - The LLM agent's response router or server state updates can check quest progress and mark elements in `currentState.tasks` as complete (`isCompleted: true`).

#### Godot Client Changes

1. **`game_manager.gd`**:
   - Add a `tasks: Array = []` field to local state.
   - Update `reset_state()` to clear tasks or load defaults.
2. **`http_agent_client.gd`**:
   - Map server `tasks` to local `GameManager.tasks` inside state parsing.
3. **`game_hud.gd`**:
   - Instead of hardcoded arrays in `_refresh()`, loop through `GameManager.tasks` dynamically:
     ```gdscript
     var quests: Array[String] = []
     for task in GameManager.tasks:
         quests.append(_format_quest(task["description"], task["isCompleted"]))
     quest_label.text = "[b][color=#d4a648]Your Path[/color][/b]\n\n" + "\n\n".join(quests)
     ```

---

## Verification Plan

### Automated/Manual Verification
- Trigger state updates that mark Quest 1, 2, and 3 complete (e.g., getting dirt from priest).
- Open the Side Drawer (`GameHUD`).
- Verify that completed tasks are colored `#7c6f62` and render with a strike through `[s]● Earn Mira's faith...[/s]`.
- Verify that active/incomplete tasks are colored `#d4a648` with a bullet `○` and do not have a strikethrough.
