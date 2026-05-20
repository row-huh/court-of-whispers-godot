# Implementation Plan: AI Provider Migration & Game State Resolution

Migration from a legacy custom AI gateway/wrapper to direct `@ai-sdk/google` usage, environment setup standardization, and resolution of a blocking bug in the night-to-day transition phase.

---

## Proposed Changes

The following modifications have been fully executed across the application.

### 1. Dependency Configurations

#### [MODIFY] [package.json](file:///d:/court-of-whispers/package.json)
- Installed the standard `@ai-sdk/google` provider to replace the legacy custom gateway provider.
- Added version `@ai-sdk/google@3.0.75` to dependencies.

---

### 2. Environment Variable Configuration

#### [MODIFY] [.env.local](file:///d:/court-of-whispers/.env.local)
- Renamed the API key variable from `GEMINI_API_KEY` to `GOOGLE_GENERATIVE_AI_API_KEY` to align with the default environment variable expected by the standard Google AI SDK.
- Removed formatting spaces around the `=` character to ensure proper parsing across diverse Node environments.

#### [MODIFY] [.env.example](file:///d:/court-of-whispers/.env.example)
- Synced the template with the new standard key `GOOGLE_GENERATIVE_AI_API_KEY` to ensure correct onboarding for other developers.

---

### 3. Backend Endpoints (API Routes)

#### [MODIFY] [agent.ts](file:///d:/court-of-whispers/src/routes/api/agent.ts)
- Removed custom integration code.
- Imported `google` from `@ai-sdk/google` directly.
- Standardized the model name to `gemini-3.1-flash-lite`.
- Restructured `generateObject` options by passing consolidated system instructions directly to the `system` parameter instead of mixing them in the `messages` array.
- Standardized error handling by returning exact status codes (e.g., 429 for rate limits, 402 for payment/credit exhaustion, 500 for generic failures) to prevent silent user-facing errors.

#### [MODIFY] [night.ts](file:///d:/court-of-whispers/src/routes/api/night.ts)
- Removed the custom gateway and switched endpoints to the direct `google` SDK.
- Re-architected parameters to supply system prompts to the `system` option rather than injecting them as standard messages.
- Updated endpoints to target the optimized model `gemini-3.1-flash-lite`.

---

### 4. Client State Machine & UI Progression

#### [MODIFY] [index.tsx](file:///d:/court-of-whispers/src/routes/index.tsx)
- **Problem**: When a day completed, `applyNightExchanges` instantly reset `pendingNight` to `false`, causing the modal UI to close prematurely before the player had a chance to read the whispers or click the "Dawn breaks" button, leaving the game state completely stuck.
- **Fix**: Removed the premature state alteration in `applyNightExchanges`. Updated `handleNightClose` to explicitly clear `pendingNight: false` when a player acknowledges and dismisses the dialog. This preserves the UI and cleanly transitions the state machine to the next day.

---

## Verification Plan

### Automated & Manual Checks
- **Installation Verification**: Confirmed `@ai-sdk/google` was safely installed and listed under the application's root dependencies.
- **API Call Validation**: Initiated conversation flows with all NPCs inside the game locally, confirming structured payloads returned correctly from the new endpoint.
- **Day-End Transition**: Verified that when all turns for the day are exhausted, the night rumors overlay opens successfully, remains visible for user evaluation, and accurately advances the state to the subsequent morning upon clicking "Dawn breaks".
