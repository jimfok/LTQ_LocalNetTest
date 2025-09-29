# Spec: local simulators for room workflows
- Spec ID: spec:sim-tools
- Status: Draft
- Owner: Agent session 2025-10-06
- Linked Plan: docs/plan/2025-10-06-sim-tools.md
- Linked Tests: tests/sim/server_sim_spec.lua, tests/sim/client_sim_spec.lua

## Purpose
Give developers single-machine room workflow coverage by adding CLI-driven simulators that mirror the in-game `Create Room` (server) and `Join Room` (client) behaviours. Each simulator must reuse existing `src/network` modules to stay in lockstep with runtime logic and emit machine-readable logs for downstream automation.

## Requirements

### R1: Server-room simulator (spec:sim-tools)
- Must let a single machine start a room lifecycle identical to the production `Create Room` flow so agents can test without an additional host.
- Reuse `RoomServer` primitives and expose deterministic flags (`--port`, `--room-id`, `--duration`) so automation can script predictable sessions.
- Emit lifecycle logs in the `TRACE|sim.server|action|status|key=value` format and gracefully stop on SIGINT while reporting outcomes for future enhancements.

### R2: Join-room simulator (spec:sim-tools)
- Must autodiscover a locally broadcast server, attempt a join, and issue keepalive pings so developers can validate the end-to-end handshake without another device.
- Reuse `Discovery` probes and `RoomServer` join logic while exposing CLI flags (`--broadcast`, `--udp-port`, `--duration`) that match the server simulator's determinism guarantees.
- Emit machine-readable logs in the `TRACE|sim.client|action|status|key=value` format and continue to run unattended so future iterations can extend behaviours (e.g., scripted latency tests).

## Preconditions
- `src/network/discovery.lua` and `src/network/room_server.lua` provide the core networking primitives.
- LuaJIT and LuaSocket are available locally (same assumptions as existing specs).
- Shell scripts under `./scripts` can invoke Lua entrypoints.

## Scenarios

### S1: Server simulator boots and accepts join payloads
1. Execute `scripts/run-room-server.sh --port 47001 --room-id 3`.
2. The script initialises a simulator module that internally constructs `RoomServer.new` with deterministic dependencies.
3. The simulator logs `TRACE|sim.server|start|ok|port=47001 roomId=3`.
4. When a TCP client sends a JSON `JoinRoom` payload, the simulator responds with `{"status":"Accept",...}` and emits `TRACE|sim.server|join|accept|peer=<ip>:<port>`.
5. Simulator exits cleanly on SIGINT (Ctrl+C) and logs `TRACE|sim.server|stop|ok`.

### S2: Client simulator discovers broadcast and pings server
1. Execute `scripts/run-room-client.sh --broadcast 255.255.255.255 --udp-port 53317`.
2. The simulator listens using `Discovery.new`, sends periodic `HELLO` probes, and logs each send with `TRACE|sim.client|discover|sent`.
3. When a pong is received, it logs `TRACE|sim.client|discover|match|peer=<id>` and triggers a TCP join attempt using `RoomServer` defaults.
4. The simulator sends a ping JSON payload, receives the `Accept` response, and prints `TRACE|sim.client|join|accept|roomId=...`.

### S3: Automation hooks for CI agents
1. Scripts accept `--duration` to cap run time for non-interactive jobs.
2. Exit status is zero when the simulator completes the requested loop without errors.
3. Non-zero exit codes are returned when dependencies fail (e.g., socket bind error) and logged as `TRACE|sim.*|error|<reason>`.

## Verification Notes
- Specs under `tests/sim/` must stub socket/json deps to simulate join/ping flows deterministically.
- Keep log format stable (`TRACE|component|action|status|key=value ...`) so future automation can parse results.
- Update `README.md` Quickstart Networking section with references to these scripts and the spec ID `spec:sim-tools`.
- ensure new shell entrypoints call Lua modules under `src/sim/` so other agents can require them for deeper automation flows.
- Capture follow-up enhancements in `docs/tasks/` with the `spec:sim-tools` tag once new simulator behaviours are identified.
