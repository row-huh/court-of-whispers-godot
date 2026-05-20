# End of Day Sequence Implementation

The End of Day sequence has been successfully implemented to wait for the player to explicitly dismiss the final dialogue before the night phase is processed and the End of Day screen appears.

## What changed

### Godot Client Updates

1. **`game_manager.gd`**:
   - Introduced a `night_phase_started` flag.
   - Removed the behavior where the night phase automatically kicks off in the background as soon as the `turns_left` hits 0.
   - Moved the `_run_night_phase()` trigger into `close_dialogue()`. Now, when the user closes the dialogue box after their 5th turn, the night phase begins.
   - Added explicit `push_state()` calls on game start (`begin_game`) and day transition (`close_night`). This ensures the backend has the updated day and reset conversation counters (e.g. Day 2, 5 turns left) before the persistent HUD polling cycle overwrites the client state back to old values.
   - Corrected Mira's starting trust value for the "citizen" agent to `50` (in both `agents` initial map and `reset_state()`), aligning Godot's offline local defaults with the server's default configuration.
   - Refactored `perform_coup` logic to trigger an immediate "Game Won" condition (`status = "won"`) upon receiving a `true` value for it from the server response, bypassing the redundant client-side threshold checks to trust the canonical server state.
   - Fixed a **stack overflow infinite recursion bug** by adding a `dialogue_open` guard to `close_dialogue()`. This breaks a circular signal loop where `status != "playing"` (when game is won/lost) triggers `dialogue_controller` to call `_on_close() -> close_dialogue()`, which emitted `state_changed` and recursively invoked the handler infinitely.
   - **Bishop Suspicion Delta Support**: Integrated full, robust support in `apply_delta()` for receiving and applying `suspicionDelta` (and `suspicion_delta`) values from the backend response. This enables the Bishop to successfully decrease or increase global suspicion dynamically during interactions, with the daily shift automatically displayed with professional green decrease arrows (`▼`) in the End of Day summary briefing.

2. **`game_ui.gd`**:
   - Updated the visibility check for the `NightModal` (the End of Day screen). It now includes a check for `not GameManager.dialogue_open`, guaranteeing that it won't overlay or conflict with the dialogue UI, even if the user closes it quickly.
   - Added programmatic styling to `NightModal` via `StyleBoxFlat` to mirror the dark-stone look, thick brown borders, drop shadow, and padding of the Side Drawer (`GameHUD`).
   - Integrated a shader-based background blur (`ColorRect` with screen-reading blur shader) placed directly behind the modal. It dynamically blurs and darkens the game environment when the End of Day summary is visible, and disappears once "Dawn breaks" is clicked.
   - **Overhauled the entire layout and text styling of the Day Change (Night Briefing) screen**:
     - Upgraded the header to a clean, stylized `✦ NIGHT X BRIEFING ✦` with custom font size and golden-amber highlights.
     - Redesigned the secret spy whispers into a centered **Dialogue Card layout** (`CITIZEN ◀ ▶ PRIEST` followed by elegant italicized quotes), fitting the palace intrigue theme.
     - Built a native **BBCode Table** (`[table=3]`) for the daily stat and influence shifts, ensuring absolute alignment of labels, values, and deltas across all screens/resolutions.
     - Created **custom status shift cells** with colored icon markers: green decreases (`▼`) for suspicion and proof, blue increases (`▲`) for priest fear, gold increases (`▲`) for trust, red increases/decreases (`▲`/`▼`) for bad outcomes, and muted stone lines (`—`) for unchanged stats.
     - Programmatically styled the **"Dawn breaks" close button** with custom normal, hover, pressed, and focus overrides. Added borders, gold highlights, hover glows, and button shadow sizes to perfectly match the drawer toggles.

3. **`game_hud.gd`**:
   - Refactored the Quest List inside the side drawer to feature five distinct game objectives synced with local state:
     - **Earn Mira's faith**: marked complete when `citizenOfferedBlackmail` is true.
     - **Press Father Edran for palace dirt**: marked complete when `priestSpilledDirt.size() > 0`.
     - **Bring the dirt back to Mira**: marked complete when `citizenAcceptedDirt` is true.
     - **Use the dirt to turn Sir Alaric**: marked complete when `agents.commander.trust >= 80`.
     - **Convince the Commander to perform the coup**: marked complete when `status == "won"`.
   - Updated `_format_quest` formatting:
     - Completed tasks are styled using a muted, dark grey-brown (`#6b5f52`), prefixed with a solid bullet (`●`), and cleanly crossed out using Godot's `[s]...[/s]` BBCode strikethrough tag.
     - Incomplete tasks are displayed in vibrant active gold (`#d4a648`) prefixed with an empty circle (`○`) and normal rendering.

- **`game_manager.gd`**: Added a global event-bus signal `signal music_stop_requested`.
- **`dialogue_controller.gd`**: Intercepted the player submitting their 5th message on Day 1 or Day 4 to emit `music_stop_requested`, stopping music immediately before the server delta arrives.
- **`game_ui.gd`**:
  - Implemented a clean sound player routine `play_song(song_name)` and `stop_song()` using `%IntroMusic`.
  - Added file-existence validation using `ResourceLoader.exists()` to safely fall back to existing soundtrack files (`without_me_medieval.mp3` or `gogoreigen.mp3`) instead of throwing errors or crashing.
  - Linked `GameManager.music_stop_requested` to trigger `stop_song()`.
  - **Smooth Decibel Fade-Out**: Programmed `stop_song()` to utilize a Godot `Tween` to logarithmically fade the music player volume db down to `-80.0` over `1.5` seconds before stopping the stream, guaranteeing no abrupt audio stops.
  - Tracked `_night_song_triggered_day` state and kept a `_fade_tween` reference to prevent volume tweens from fighting during transitions or polls.
  - **Dynamic Audio Path Resolution & Resilient Looping**: Enhanced `play_song()` to automatically scan multiple directories sequentially (`res://assets/audios/`, `res://assets/audio/`, and `res://assets/music/`) to successfully resolve and locate songs. This fixes plural vs singular folder issues in the filesystem (such as `assets/audios` vs `assets/audio`). Configured all soundtracks (including fallback medieval tracks and the main intro theme) to **loop programmatically** (`stream.loop = true`), preventing them from going silent after 3 minutes! To prevent any runtime import or format issues, added a **resilient cascading fallback loader** for `reigen.mp3` which tries `res://assets/music/gogoreigen.mp3`, `res://assets/audios/gogoreigen.mp3`, and `res://assets/audio/gogoreigen.mp3` in sequence before reverting to the default medieval background music.
  - Programmatically constructed custom interactive popup banners (`_show_custom_banner()` with a gorgeous gold border, dark background, rounded corners, spacing, and hover effects matching the game UI).
  - Intercepted "Dawn breaks" close triggers:
    - **Removed Day 1/Day 2 Custom Banner**: Removed the pop-up dialogue banner completely when closing the Night 1 summary (transitioning into Day 2) as requested. The game now proceeds smoothly and directly into Day 2, while the beautiful theme music plays in the background.
    - **Refined Day 4 Warning Banner**: Displays `"You have only 2 more days!"` with a matching lowercase `"continue.."` confirmation before entering the final day.
    - The confirmation choice safely executes `GameManager.close_night()`.
  - **Dynamic Continue & Loading Button**:
    - Renamed the default close button text from `"Dawn breaks"` to `"continue"`.
    - Automated disabled/enabled state checks based on `GameManager.request_pending`. When transitioning to night, the close button is immediately styled with an exquisite muted/disabled stylebox, disabled from click interactions, and sets text to `"loading..."`.
    - Displayed a rotating hourglass icon (`⌛`) above the loading message (`⌛ The court whispers...`) during asynchronous network loads.
    - Automatically unlocks, changes text back to `"continue"`, and restores fully interactive gold-bordered styles once the night delta response arrives.

### Backend Alignment
- Confirmed that the backend in `court-of-whispers` relies solely on the HTTP requests and state updates generated by Godot. Since Godot dictates the timing by waiting to call `/api/night` and push the updated state, the backend implicitly supports this behavior without requiring any server-side logic modifications.


## Validation

The day flow now behaves like this:
1. Turn 5 finishes.
2. The agent responds, and the dialogue box stays open displaying the agent's response.
3. The player presses "Continue" when they finish reading.
4. The dialogue box cleanly disappears.
5. The night phase begins processing, and the End of Day summary screen elegantly fades in.
6. **Async Load**: A stylized spinning hourglass `⌛` appears, the close button is locked (`disabled`), and the button displays `"loading..."`.
7. **Complete**: When the night data is fetched, the logs and tables populate, the button changes to `"continue"`, and becomes clickable.
8. The player reviews the log, presses `"continue"`, and advances the day.
