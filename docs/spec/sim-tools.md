# spec:sim-tools Simulation Tooling Flows
- Spec ID: spec:sim-tools
- Status: Draft
- Owner: Agent session 2025-10-06
- Linked Plan: docs/plan/2025-10-06-sim-tools.md (active iteration), docs/plan/2025-09-30-sim-tools.md (historical checkpoints)
- Linked Tasks: docs/tasks/2025-10-06-sim-tools.md, docs/tasks/2025-09-30-sim-tools.md
- Linked Tests: tests/sim-tools/simulation_created_room_spec.lua (S1), tests/sim-tools/simulation_join_room_spec.lua (S2)

## Overview
This spec clarifies the behaviour of the simulation tooling workflows so that developers can reliably reproduce and debug matchmaking flows without live players. The active roadmap lives in [docs/plan/2025-10-06-sim-tools.md](../plan/2025-10-06-sim-tools.md) and builds on the earlier checkpoints in [docs/plan/2025-09-30-sim-tools.md](../plan/2025-09-30-sim-tools.md). Guidance captured on the `feature/sim-tools-requirements` branch is folded into this document so the active plan and historical expectations stay in one place.

## Purpose
Give developers single-machine room workflow coverage by adding CLI-driven simulators that mirror the in-game `Create Room` (server) and `Join Room` (client) behaviours. Each simulator must reuse existing `src/network` modules to stay in lockstep with runtime logic and emit machine-readable logs for downstream automation.

## Runtime Touchpoints
- `main/main.script` owns the room creation and join flows exposed through the in-game HUD. These flows remain reserved for the shipping experience; simulators must not post messages into the HUD or reuse its buttons.
- `main/ui.gui_script` exposes the Create/Join buttons and relays user input to `main/main.script`. No simulator work should rename or rebind these controls—automation interacts strictly through CLI entry points.
- `src/ui/model.lua` stores peer metadata, per-state status text, and chronological logs for the runtime HUD. The simulators can read protocol constants from shared modules but must not mutate this UI state.
- `src/sim-tools/simulation_created_room.lua` wraps the runtime `RoomServer` lifecycle in the `run_simulation_created_room()` harness so CLI scripts can boot the Simulation-Created Room flow without touching UI collections.
- `src/sim-tools/simulation_join_room.lua` exposes the complementary `run_simulation_join_room()` harness that reuses `Discovery` probes for the Simulation-Join Room workflow.
- `scripts/sim-tools/` houses CLI entry points. These scripts emit `TRACE|sim.*|…` lines so downstream tooling can assert behaviour without relying on HUD mirrors.

## Spec ↔ Code Map
- **Simulator Harnesses**: `src/sim-tools/simulation_created_room.lua` and `src/sim-tools/simulation_join_room.lua` are the single entry points for automation. Both files tag TODOs with `spec:sim-tools` so follow-up work can reference this spec when wiring CLI flags, TRACE logging, and graceful shutdown logic.
- **Behaviour Specs**: `tests/sim-tools/simulation_created_room_spec.lua` (Scenario S1) and `tests/sim-tools/simulation_join_room_spec.lua` (Scenario S2) mirror the simulator expectations. Keep describe blocks referencing `spec:sim-tools` for traceability when adding new assertions.
- **Plans & Tasks**: `docs/plan/2025-10-06-sim-tools.md` and `docs/tasks/2025-10-06-sim-tools.md` must refer to the simulator harness names above to avoid drift between planning notes and executable code.

## Requirements
### R1: Server-room simulator (spec:sim-tools)
- Must let a single machine start a room lifecycle identical to the production `Create Room` flow so agents can test without an additional host.
- Reuse `RoomServer` primitives and expose deterministic flags (`--port`, `--room-id`, `--duration`) so automation can script predictable sessions.
- Emit lifecycle logs in the `TRACE|sim.server|action|status|key=value` format and gracefully stop on SIGINT while reporting outcomes for future enhancements.
- Operate entirely from CLI scripts; never require HUD interactions or modifications under `main/`.

### R2: Join-room simulator (spec:sim-tools)
- Must autodiscover a locally broadcast server, attempt a join, and issue keepalive pings so developers can validate the end-to-end handshake without another device.
- Reuse `Discovery` probes and `RoomServer` join logic while exposing CLI flags (`--broadcast`, `--udp-port`, `--duration`) that match the server simulator's determinism guarantees.
- Emit machine-readable logs in the `TRACE|sim.client|action|status|key=value` format and continue to run unattended so future iterations can extend behaviours (e.g., scripted latency tests).
- Operate entirely from CLI scripts; never require HUD interactions or modifications under `main/`.

## Terminology & Isolation Updates
- Keep the shipping HUD labels (**Create Room**, **Join Room**) untouched; simulator naming lives in CLI help text and documentation.
- Refer to CLI harnesses as **Simulation-Created Room** and **Simulation-Join Room** in docs, scripts, and tests to distinguish them from the HUD flows without altering UI assets.
- Document any simulator terminology changes inside `docs/spec/` and CLI usage strings instead of modifying `main/ui.gui` resources.

## Proof-of-Concept Scope
During the initial phase the simulation tools mirror the production Create Room / Join Room flows without requiring real player clients. Simulator entry points operate purely from shell scripts that spawn the harness loops; no simulator work injects messages into HUD scripts or rebinds GUI nodes. Future iterations can revisit optional HUD mirrors once CLI automation is stable.

## Instrumentation & Orchestration
- Emit lightweight console logs in `main/main.script` (e.g. `TRACE|sim-tools|simulation-created-room|ok`) when HUD-driven flows fire so developers can correlate actions while debugging without new telemetry pipelines. These logs remain read-only touchpoints for simulators.
- Simulator scripts emit structured lines (`TRACE|sim.server|…`, `TRACE|sim.client|…`) that capture action, status, and key metadata (`port`, `roomId`, `peer`). Keep both log families stable to support manual runs and future automation.
- Coordinate the self-test via shell scripts—run the room server harness and the join harness from terminals using the wrappers listed below. HUD interactions stay optional for manual observation only.
  - `./scripts/run-room-server.sh --duration 5`
  - `./scripts/run-room-client.sh --duration 5`

## Scenarios
### S1: Simulation-Created Room boots and accepts join payloads
1. Execute `scripts/run-room-server.sh --port 47001 --room-id 3`.
2. The script initialises `src/sim-tools/simulation_created_room.lua` (harness: `run_simulation_created_room`) which internally constructs `RoomServer.new` with deterministic dependencies.
3. The simulator logs `TRACE|sim.server|start|ok|port=47001 roomId=3`.
4. When a TCP client sends a JSON `JoinRoom` payload, the simulator responds with `{"status":"Accept",...}` and emits `TRACE|sim.server|join|accept|peer=<ip>:<port>`.
5. Simulator exits cleanly on SIGINT (Ctrl+C) and logs `TRACE|sim.server|stop|ok`.

### S2: Simulation-Join Room discovers broadcast and pings server
1. Execute `scripts/run-room-client.sh --broadcast 255.255.255.255 --udp-port 53317`.
2. The simulator delegates to `src/sim-tools/simulation_join_room.lua` (harness: `run_simulation_join_room`) which listens using `Discovery.new`, sends periodic `HELLO` probes, and logs each send with `TRACE|sim.client|discover|sent`.
3. When a pong is received, it logs `TRACE|sim.client|discover|match|peer=<id>` and triggers a TCP join attempt using `RoomServer` defaults.
4. The simulator sends a ping JSON payload, receives the `Accept` response, and prints `TRACE|sim.client|join|accept|roomId=...`.

### S3: Automation hooks for CI agents
1. Scripts accept `--duration` to cap run time for non-interactive jobs.
2. Exit status is zero when the simulator completes the requested loop without errors.
3. Non-zero exit codes are returned when dependencies fail (e.g., socket bind error) and logged as `TRACE|sim.*|error|<reason>`.

## Use Cases
### Test player join room
1. Execute **Simulation-Created Room** via `scripts/sim-tools/simulation-created-room.sh`. The CLI harness binds `RoomServer` and discovery listeners without touching HUD scripts, logging `TRACE|sim.server|start|ok` on success.
2. From the game UI (`main/ui.gui_script`), invoke **Join Room** for manual validation only. This fires `ACTION_JOIN_ROOM`, causing `start_client` to bind a local UDP socket and immediately send a ping via `send_ping`.
3. Debug or troubleshoot the join-room flow via the game UI or developer tools. Expect the join panel log (backed by `UiModel.append_log`) to show an outbound `-> broadcast` line followed by inbound `pong` messages from the simulator. No simulator code should mutate UI nodes.

### Test player create room
1. From the game UI (`main/ui.gui_script`), execute **Create Room** to open a new room for manual checks. This transitions to `STATE_CREATE`, binding the UDP server and logging `Hosting on <ip>:53317`.
2. Run **Simulation-Join Room** via `scripts/sim-tools/simulation-join-room.sh` to emulate a player joining. The CLI harness emits JSON ping payloads matching `send_ping` without requiring HUD callbacks.
3. Debug or troubleshoot the create-room flow via the game UI or developer tools. Watch for inbound `ping` entries in the Create panel log while the simulator reports `TRACE|sim.client|join|accept|roomId=…`. Keep HUD assets read-only during these tests.

### Simulation tooling self-test
1. Run **Simulation-Created Room** on one process using `scripts/sim-tools/simulation-created-room.sh`. Confirm the console logs include both the `TRACE|sim.server|start|ok` line and the `[INFO] LocalNetTest…` readiness message.
2. Run **Simulation-Join Room** on two additional processes using `scripts/sim-tools/simulation-join-room.sh`. Each should send the JSON ping payload and wait for pong responses, printing `TRACE|sim.client|join|accept|roomId=…` when the payload is acknowledged.
3. Verify that all operations complete successfully, capturing outcomes in `docs/tasks/2025-09-30-sim-tools.md` and `docs/tasks/2025-10-06-sim-tools.md`. Use CLI exit codes and TRACE logs as the source of truth; HUD logging is optional for manual inspection.

## Validation Checklist
- [ ] Simulator terminology appears in CLI help text and docs only; HUD labels remain unchanged.
- [ ] Simulated flows continue to mirror game UI interactions without additional player clients while remaining HUD-isolated.
- [ ] Lightweight `TRACE|sim-tools|…` and CLI `TRACE|sim.*|…` console entries are emitted when simulator scripts run their harness loops.
- [ ] Developers can execute the scenarios above without manual data setup and can rely on the linked task trackers to log outcomes.
- [ ] Future spec updates synchronise with the listed plan, task, and test documents so executor agents inherit the same expectations.
- [ ] `src/sim-tools/` harness names and `tests/sim-tools/` spec filenames stay aligned with `docs/plan/2025-10-06-sim-tools.md` and `docs/tasks/2025-10-06-sim-tools.md` references.
