# Core Interaction System & Army Commander Agent Implementation

This plan outlines the steps to build an autonomous agent system for the RPG, centered around "The Army Commander" agent. The system will use a Python backend for logic and an Expo (React Native) frontend for the game interface.

## User Review Required

> [!IMPORTANT]
> This implementation requires **Ollama** to be running locally with the `llama3.1` model installed for the agent's dialogue generation.
> The backend will run on `localhost:8000`.

> [!NOTE]
> The "Coup" victory condition is gated by `trust > 80` and `suspicion < 40` in the world state, which are influenced by the player's conversation with the Army Commander.

## Proposed Changes

### Backend Implementation

#### [NEW] [pathfinding.py](file:///home/row-huh/Documents/experiments/serial-experiments-game-dev/backend/tools/pathfinding.py)
- Implement A* pathfinding algorithm.
- Input: start, target, grid (collision matrix).
- Output: List of coordinates.

#### [NEW] [locations.py](file:///home/row-huh/Documents/experiments/serial-experiments-game-dev/backend/tools/locations.py)
- Manage character positions in the backend.
- Provide `get_character_locations()` tool for agents.

#### [NEW] [talk.py](file:///home/row-huh/Documents/experiments/serial-experiments-game-dev/backend/tools/talk.py)
- Manage conversation state (locks, participants, turns).
- Ensure only one agent/player speaks at a time.

#### [NEW] [coup.py](file:///home/row-huh/Documents/experiments/serial-experiments-game-dev/backend/tools/coup.py)
- Logic for triggering the "Coup" victory state.
- Validates world state conditions before execution.

#### [NEW] [world_state.py](file:///home/row-huh/Documents/experiments/serial-experiments-game-dev/backend/world_state.py)
- Handle loading and saving of JSON-based world state and agent memory.
- Files: `backend/memory/global_state.json`, `backend/memory/agents/*.json`.

#### [NEW] [army_commander.py](file:///home/row-huh/Documents/experiments/serial-experiments-game-dev/backend/agents/army_commander.py)
- Core agent logic for the Army Commander.
- Integrates with Ollama for dynamic dialogue.
- Processes player input and updates memory/trust/suspicion.

#### [NEW] [scheduler.py](file:///home/row-huh/Documents/experiments/serial-experiments-game-dev/backend/scheduler.py)
- Background loop that invokes agents every 60 seconds or on specific events.

#### [NEW] [main.py](file:///home/row-huh/Documents/experiments/serial-experiments-game-dev/backend/main.py)
- FastAPI server to expose endpoints for the frontend.
- Endpoints: `/locations`, `/interact`, `/chat`, `/state`.

### Frontend Implementation

#### [MODIFY] [index.tsx](file:///home/row-huh/Documents/experiments/serial-experiments-game-dev/app/(tabs)/index.tsx)
- Integrate with the backend API.
- Render the Army Commander agent on the map.
- Add proximity detection (show "Press X to talk").
- Implement a Conversation UI overlay.
- Handle victory/game over screen.

## Verification Plan

### Automated Tests
- Test pathfinding utility independently.
- Curl tests for API endpoints.

### Manual Verification
- Move player near Army Commander.
- Verify interaction prompt appears.
- Engage in conversation and check if agent responds (Ollama).
- Attempt to trigger `coup()` by building trust and reducing suspicion.
- Verify Game Over screen on successful coup.
