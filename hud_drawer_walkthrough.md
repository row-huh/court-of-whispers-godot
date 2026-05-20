# HUD Drawer Walkthrough

I have successfully transformed the UI into a drawer-style menu! Here is a rundown of the changes:

## 1. The Drawer Toggle
A new **"☰" Toggle Button** is now fixed to the top-left of the screen.
When you tap it, the entire HUD container smoothly slides in and out from the left edge of the screen using a fluid sine-wave easing animation (`Tween`). When the game status isn't "playing", the drawer seamlessly tucks itself away.

## 2. Updated Aesthetic
The `GameHUD` container now features a dark brown, edge-hugging style (`#1f1814`) with a sleek border.
- The Day indicator matches your mockup exactly: large golden text (`Day 1 of 5`).
- The turn counter has been rephrased to the softer text `5 words left today` and right-aligned.

## 3. Custom Progress Bars
Every metric (Trust, Fear, Suspicion) has been split into a dedicated layout block:
- **Title and Value**: The character name/stat is uppercase and colored in an earthy brown (`#8a7b6b`), with the numeric value (`30`, `0`, etc.) right-aligned to match.
- **Custom Fills**: We replaced the default green bars. Positive stats (like Trust) fill with a bright gold (`#d4a648`), while negative stats (Fear, Proof, Suspicion) use a very dim, dark red/brown fill that stays out of sight when low. 

## 4. "Your Path" Checklist
The `game_hud.gd` logic has been entirely rebuilt to show the full list of your objectives under the golden **Your Path** header.
- Tasks dynamically use `○` when incomplete and `●` when finished.
- It will read from the `GameManager` flags (e.g. `citizen_offered_blackmail`) to know which nodes to check off in real time as you play.

Go ahead and run the game to test out the new sliding drawer!
