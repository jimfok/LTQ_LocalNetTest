# Simulation Tools Validation Checklist (spec:sim-tools)

The previous scaffolding attempt introduced code placeholders before the supporting plans were finalised. This checklist captures
what still needs to exist **in documentation first** so future agents can recreate the missing files with comment-only pseudo-code
and avoid shipping premature implementations.

## Pending Artifact Layout
- `src/sim-tools/cli.lua` & `src/sim-tools/harness/`: establish module skeletons with comment-only pseudo-code for parsing,
  dispatch, and scheduler helpers before adding executable logic.
- `src/sim-tools/logging.lua` & `src/sim-tools/log_sinks.lua`: outline logging intent (TRACE families, sink strategy) purely in
  comments so later work can wire structured logging without guessing naming.
- `tests/sim-tools/simulation_cli_spec.lua` & `tests/support/sim_tools_fakes.lua`: describe the intended test surfaces and fake
  helpers that will exercise CLI parsing and harness loops once the code lands.

## Shell Entrypoint Expectations
- Restore wrapper scripts `scripts/run-room-server.sh` and `scripts/run-room-client.sh` as documented placeholders that call into
  the CLI module once it exists.
- Keep `scripts/sim-tools/simulation-created-room.sh` and `scripts/sim-tools/simulation-join-room.sh` as echo-only stubs until the
  CLI bridge is ready; document the future `lua src/sim-tools/cli.lua ...` commands inside comments rather than wiring them now.

## Documentation Alignment Tasks
- Mirror these placeholder expectations in `docs/spec/sim-tools.md` under a dedicated "Current Status" section so spec, plan, and
  tasks remain in sync.
- Update `docs/tasks/2025-10-06-sim-tools.md` with checkboxes pointing back to this checklist so executor agents know which
  scaffolding artifacts to recreate with comment-only pseudo-code.

## Validation Checklist (to execute after scaffolding lands)
- [ ] Run `./scripts/run-room-server.sh --duration 3` once the CLI bridge is implemented and documented.
- [ ] Run `./scripts/run-room-client.sh --duration 3` after the client harness placeholder exists, capturing TRACE samples in
      follow-up task notes.
- [ ] Record sample TRACE output for both flows in `docs/tasks/2025-10-06-sim-tools.md` to close the loop between code and plan.
