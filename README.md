# Welcome to Defold

This project was created from the "mobile" project template. This means that the settings in ["game.project"](defold://open?path=/game.project) have been changed to be suitable for a mobile game:

- The screen size is set to 640x1136
- The projection is set to Fixed Fit
- Orientation is fixed vertically
- Android and iOS icons are set
- Mouse click/single touch is bound to action "touch"
- A simple script in a game object is set up to receive and react to input
- Accelerometer input is turned off (for better battery life)

[Build and run](defold://build) to see it in action. You can of course alter these settings to fit your needs.

Check out [the documentation pages](https://defold.com/learn) for examples, tutorials, manuals and API docs.

If you run into trouble, help is available in [our forum](https://forum.defold.com).

Happy Defolding!

---

### Local network discovery

The file `src/network/discovery.lua` sets up a multicast UDP listener and broadcasts a `HELLO` message with the device ID and model. This allows instances of the game on the same network to announce themselves and detect others. `main/main.script` shows how the module is initialized and used each frame.

### Room simulator workflows (spec:sim-tools)

- Follow `docs/spec/sim-tools.md` for full requirements and logging expectations that keep the simulators aligned with runtime logic.
- The server-room harness (to be exposed as `scripts/run-room-server.sh`) bootstraps `RoomServer` with deterministic flags like `--port`, `--room-id`, and `--duration`, then emits machine-readable lines such as `TRACE|sim.server|start|ok|port=47001 roomId=3`.
- The join-room harness (planned as `scripts/run-room-client.sh`) reuses `Discovery` probes to broadcast, auto-match servers, and report progress via `TRACE|sim.client|discover|sent` / `TRACE|sim.client|join|accept|roomId=...`.
- Use these simulators to validate create/join flows on a single machine while other devices or agents are offline; capture follow-up tasks in `docs/tasks/2025-10-06-sim-tools.md` when behaviour evolves.

## Spec-driven architecture

Spec-driven, AI-assited workflow's alignment
Spec -> baseline requirements, under `docs/spec`
Plan -> iteration steps for AI/agents, under `docs/plan`
Tasks -> bite-size actionable units, sometimes auto-generated from plan, under `docs/tasks`
ADRs -> gauardrails and historical reasoning, under `docs/adrs`

- Network code now lives under `src/network`, making it reusable from both runtime scripts and unit specs.
- `main/main.script` creates a `Discovery` instance, which exposes `listen`, `broadcast_hello`, `receive`, and `close` instance methods.
- Behavioural specs reside in `tests/network` and assume the [Busted](https://lunarmodules.github.io/busted/) runner (`luarocks install busted` then `busted tests`).
- Specs rely on dependency injection; production code uses Defold's `socket`, `json`, and `sys` while tests stub these interfaces.
- Shared doubles live under `tests/support` (for example, `tests/support/network_context.lua`) so new specs can require an existing context instead of rewriting stubs.
- Override the UDP port via `game.project` (add `[network]` → `discovery_port = 53317`, for example) to run multiple instances on the same machine.

### Tests vs specs

- Prefer authoring unit and behaviour specs under `tests/`; `docs/spec/` stores narrative outlines that feed those executables, while integration harnesses can grow alongside them when needed.
- Run the full networking spec suite with `./scripts/test-network.sh`, or pass individual files/dirs to `./scripts/test.sh` for focused runs.

## Development workflow

- Install LuaRocks + Busted for LuaJIT: `luarocks --lua-version=5.1 --lua-interpreter=luajit install busted --local`.
- Run `./scripts/test.sh` to execute the full spec suite; pass extra arguments (for example, `./scripts/test.sh tests/network/discovery_spec.lua`) for focused runs without reconfiguring your shell.
- Use `busted tests/network/discovery_spec.lua` (or the room server spec) for focused runs while iterating.
- Use `./scripts/build.sh` to invoke `tools/bob.jar` with Java 21+, or pass custom flags such as `./scripts/build.sh --archive --platform armv7-android bundle`.
- Use `./scripts/bob-smoke.sh` to exercise Bob's `resolve`, `build`, and `bundle` commands in sequence (pass `--platform` to target a different runtime).
- Download Bob separately from the Defold editor (`Help → Download Bob`) and place it at `tools/bob.jar`; the file is `.gitignore`d so each developer/CI runner keeps a local copy.
- The project vendors [dkjson](https://github.com/LuaDist/dkjson) as `json.lua` (MIT) to keep `require "json"` working for both Busted and Bob builds without external Lua modules.
- Update `game.project` if you need unique network settings per build (for example, change `[network] discovery_port`).
