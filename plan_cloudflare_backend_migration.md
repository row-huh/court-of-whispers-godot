# Implementation Plan - Production HTTP AI Backend Migration

This plan details the steps required to transition the game's AI NPC backend from a local server running on `http://127.0.0.1:8080` to your production Cloudflare Worker link (`https://tanstack-start-app.court-of-whispers.workers.dev/`). This migration will resolve the network failure errors encountered on itch.io.

## Suggestion Analysis & Feasibility

Your suggestion to replace `http://127.0.0.1:8080` with `https://tanstack-start-app.court-of-whispers.workers.dev` is **100% correct and is the exact solution needed** to make the itch.io deployment work.

### Why this error occurs:
1. **Localhost Isolation**: A web browser running a game hosted on `itch.io` cannot access `127.0.0.1` or `localhost` of the player's computer because of standard browser sandbox security.
2. **Mixed Content Block**: Since `itch.io` is hosted securely via `https://`, modern browsers strictly block any outgoing requests to non-secure `http://` URLs (like `http://127.0.0.1:8080`).

### Why your solution works:
1. **Production Worker**: Shifting requests to your live Cloudflare Worker gives the game a globally accessible API endpoint.
2. **HTTPS Protocol**: Your Cloudflare Worker uses `https://`, matching the security profile of `itch.io` and satisfying the browser's mixed content requirements.
3. **Dynamic Routes**: You **do not need to append specific endpoints** (like `/api/agent` or `/api/state`) directly to the base URL in the configuration. The codebase is designed to automatically append these routes (`/api/agent`, `/api/state`, `/api/night`) to whatever base URL is defined in the configuration.

---

## User Review Required

> [!IMPORTANT]
> **CORS Configuration on the Cloudflare Worker**
> Modern web browsers enforce **CORS (Cross-Origin Resource Sharing)**. Because your web game is hosted on `itch.io` (e.g. `https://html5.api.itch.zone` or similar), your Cloudflare Worker's endpoints (`/api/agent`, `/api/state`, `/api/night`) must return appropriate CORS response headers (such as `Access-Control-Allow-Origin: *` or `Access-Control-Allow-Origin: https://...`).
> If you experience preflight (`OPTIONS`) or CORS errors in the browser console after this migration, ensure your Cloudflare Workers backend has CORS enabled.

---

## Proposed Changes

We will update all instances of the local base URL (`http://127.0.0.1:8080`) to point to the secure production base URL: `https://tanstack-start-app.court-of-whispers.workers.dev`.

### Godot Configuration & Scripts

#### [MODIFY] [game_config.tres](file:///d:/court-of-whispers-godot/data/game_config.tres)
* Update `api_base_url` parameter from `"http://127.0.0.1:8080"` to `"https://tanstack-start-app.court-of-whispers.workers.dev"`.

#### [MODIFY] [game_config.gd](file:///d:/court-of-whispers-godot/scripts/game_config.gd)
* Update default `@export var api_base_url` value to `"https://tanstack-start-app.court-of-whispers.workers.dev"`.

#### [MODIFY] [http_agent_client.gd](file:///d:/court-of-whispers-godot/scripts/http_agent_client.gd)
* Update the `DEFAULT_BASE_URL` constant fallback value to `"https://tanstack-start-app.court-of-whispers.workers.dev"`.

#### [MODIFY] [game_hud.gd](file:///d:/court-of-whispers-godot/scripts/game_hud.gd)
* Update the fallback private variable `_base_url` from `"http://127.0.0.1:8080"` to `"https://tanstack-start-app.court-of-whispers.workers.dev"`.

---

## Verification Plan

Since we are running in a local environment but target a live service, we will verify:

### Automated/Local Tests
1. **Run the Game Locally in Godot**: Launch the game in debug mode and initiate NPC conversations. Ensure that the game talks to the production Cloudflare Worker server correctly and handles responses (assuming the live backend is functional and running).
2. **Inspect HTTP Traffic / Logs**: Double-check that requests are directed to `https://tanstack-start-app.court-of-whispers.workers.dev/api/agent` instead of the local address.

### Manual Verification
1. Export a web build or run the game and confirm that no console errors appear indicating a network failure.
2. Confirm with the user that deploying this updated build to itch.io resolves the issue.
