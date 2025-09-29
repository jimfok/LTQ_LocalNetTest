# spec:sim-tools Simulation Tooling Flows

## Overview
This spec clarifies the behaviour of the simulation tooling workflows so that developers can reliably reproduce and debug matchmaking flows without live players. See the execution roadmap in [docs/plan/2025-09-30-sim-tools.md](../plan/2025-09-30-sim-tools.md) for implementation milestones. The guidance captured on the `feature/sim-tools-requirements` branch is now merged into this document so the active plan and historical expectations stay in one place.

## Runtime Touchpoints
- `main/main.script` owns the room creation and join flows exposed through the in-game HUD. It reacts to GUI button events (`ACTION_CREATE_ROOM`, `ACTION_JOIN_ROOM`) by starting or tearing down the UDP server/client helpers and keeps the UI model in sync.
- `main/ui.gui_script` exposes the Create/Join buttons and relays user input to `main/main.script`. It reads status and log buffers through `src/ui/model.lua`.
- `src/ui/model.lua` stores peer metadata, per-state status text, and chronological logs. Simulator automation should keep using these helpers instead of writing directly to GUI nodes.
- `scripts/sim-tools/` houses the CLI entry points. The placeholders should evolve into wrappers that either drive a headless build (via Bob) or emit the same `TRACE|sim-tools|…` lines that `main/main.script` prints when it transitions states so downstream tooling can assert behaviour.

Mirror these touchpoints while keeping the merged `feature/sim-tools-requirements` guidance in mind—its requirements about Create/Join parity are already implemented in `main/main.script`, so the current plan layers observability and orchestration on top of those functions instead of rebuilding the flows from scratch.

## Branch Merge Outcomes — `feature/sim-tools-requirements`
- **Reuse the existing runtime hooks.** Keep the simulator entry points driving `main/main.script` through `change_state(self, STATE_CREATE)` / `change_state(self, STATE_JOIN)` so the UDP server/client helpers and log propagation remain identical to the HUD experience.
- **Centralise status/log surfaces.** Continue routing messaging through `UiModel` (`src/ui/model.lua`) and layer the lightweight `TRACE|sim-tools|…` console output captured in this spec. Treat these logging expectations as canonical now that the branch guidance is folded in.
- **Parameterise CLI shims cautiously.** The placeholders in `scripts/sim-tools/` should evolve toward the CLI expectations captured in the experiment (custom peer IDs, broadcast overrides) while defaulting to the current HUD-driven values until those flags are implemented.
- **Track deferred automation.** Retain the manual multi-process orchestration documented below and echo outstanding automation follow-ups in `docs/tasks/2025-09-30-sim-tools.md` so we honour the backlog the branch captured without blocking the proof-of-concept.

## Terminology Updates
- Rename the existing **Create Room** simulation action to **Simulation-Created Room**.
- Rename the existing **Join Room** simulation action to **Simulation-Join Room**.

These labels distinguish simulated flows from the in-game UI actions while keeping the original behaviour intact during the proof-of-concept phase. Update the following entry points when rolling out the terminology change:

- `main/ui.gui_script` button labels for the simulator actions.
- `main/main.script` status copy surfaced in the simulation HUD.
- Quick-launch scripts under `scripts/sim-tools/`.

## Proof-of-Concept Scope
During the initial phase the simulation tools mirror the production Create Room / Join Room flows without requiring real player clients. Player interaction continues to happen through the existing game UI, and simulator entry points simply trigger the same state transitions (`change_state(self, STATE_CREATE)` / `change_state(self, STATE_JOIN)`) that the HUD already uses.

## Instrumentation & Orchestration
- Emit lightweight console logs in `main/main.script` (e.g. `TRACE|sim-tools|simulation-created-room|ok`) to mark when simulator flows are triggered so developers can correlate actions while debugging without setting up telemetry pipelines.
- Coordinate the self-test via a simple manual multi-process setup—run the room creation action on one process and join actions on two others—to keep the proof-of-concept quick to execute.

## Use Cases
### Test player join room
1. Execute **Simulation-Created Room** via `scripts/sim-tools/simulation-created-room.sh` to create the mock room. The script should either drive a headless build or emit a `msg.post(main:/go#main, "ui_action", { action = hash("create_room") })` equivalent so the runtime calls `start_server` and prints `TRACE|sim-tools|simulation-created-room|triggered`.
2. From the game UI (`main/ui.gui_script`), invoke **Join Room**. This fires `ACTION_JOIN_ROOM`, causing `start_client` to bind a local UDP socket and immediately send a ping via `send_ping`.
3. Debug or troubleshoot the join-room flow via the game UI or developer tools. Expect the join panel log (backed by `UiModel.append_log`) to show an outbound `-> broadcast` line followed by inbound `pong` messages from the simulator.

### Test player create room
1. From the game UI (`main/ui.gui_script`), execute **Create Room** to open a new room. This transitions to `STATE_CREATE`, binding the UDP server and logging `Hosting on <ip>:53317`.
2. Run **Simulation-Join Room** via `scripts/sim-tools/simulation-join-room.sh` to emulate a player joining. The script should mirror the client path by emitting the same JSON ping payload that `send_ping` generates (`{ "type": "ping", "peer_id": … }`) so the in-game server responds with a pong.
3. Debug or troubleshoot the create-room flow via the game UI or developer tools. Watch for inbound `ping` entries in the Create panel log and ensure the simulator captures the corresponding pong.

### Simulation tooling self-test
1. Run **Simulation-Created Room** on one process using `scripts/sim-tools/simulation-created-room.sh`. Confirm the console logs include both the `TRACE|sim-tools|simulation-created-room|triggered` line and the `[INFO] LocalNetTest…` readiness message.
2. Run **Simulation-Join Room** on two additional processes using `scripts/sim-tools/simulation-join-room.sh`. Each should send the JSON ping payload and wait for pong responses, printing `TRACE|sim-tools|simulation-join-room|ok` when the payload is acknowledged.
3. Verify that all operations complete successfully, capturing outcomes in `docs/tasks/2025-09-30-sim-tools.md`. Use the per-state status text (via `UiModel.get_status`) to record whether sockets bound correctly and note any `[WARN]` lines surfaced by `main/main.script`.

## Validation Checklist
- [ ] Simulation labels updated throughout tooling UI and documentation.
- [ ] Simulated flows continue to mirror game UI interactions without additional player clients.
- [ ] Lightweight `TRACE|sim-tools|…` console entries are emitted when simulator scripts or UI buttons trigger the flows.
- [ ] Developers can execute the three use cases above without manual data setup and can rely on `docs/tasks/2025-09-30-sim-tools.md` to log outcomes.
