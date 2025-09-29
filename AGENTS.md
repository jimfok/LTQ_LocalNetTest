# Agent Guidelines

## Repository Guardrails
- Hard requirement: this repository does not use Git LFS. Do not commit or push any file that is 100 MB or larger. Run `git ls-files --stage` / `git status --short` and check sizes (e.g. `git ls-files -z | xargs -0 ls -lh`) before committing.
- If you introduce new generated or binary assets, add them to `.gitignore` instead of versioning them, and ensure existing ignores stay intact.
- Prefer keeping large build artifacts (editors, SDKs, archives) out of the repo; store them in release storage or re-download on demand.
- When creating branches from the Codex CLI agent, use the naming pattern `feature/<topic>` to keep automation and reviews consistent.

## AI Agent Alignment & Traceability
- Treat every change as agent-executable: note intent before coding in `README.md`, `docs/plan/`, or `docs/spec/` so Qwen 30B Instruct and local runners inherit the same playbook.
- Leave structured breadcrumbs—update test descriptions, commit messages, and inline comments with the feature or spec ID (`spec:<topic>`) so generated traces stay searchable.
- Sync scenario outlines between `docs/spec/` and the matching `tests/<domain>` files; cross-link the doc in the spec header for quick pivots between design and execution.
- Keep reusable automation logic in `src/` or `tools/` and expose deterministic entrypoints (`scripts/*.sh`, `tests/support/*.lua`) that agents can invoke without manual tweaking.
- Prefer hermetic logging over ad-hoc prints. When adding new scripts, emit machine-readable lines (e.g. `TRACE|component|action|status`) to help downstream agents audit execution.
- When handing off in-progress work to executor agents, capture the active branch, open tasks, and required commands at the top of the relevant doc to maintain continuity.

## Spec-Driven Project Layout
- Start with executable specs. Mirror directories under `tests/` with their runtime counterparts (`tests/network` ↔ `src/network`) so coverage stays discoverable.
- Extend `tests/support/` helpers instead of duplicating setup logic in specs; keep fixtures side-effect free and document new helpers with usage notes at the top of the file.
- Record scenario outlines in `docs/spec/` when behaviour crosses modules, then link those outlines from the related test files and update `docs/tasks/` for any follow-up work.
- When adding new root-level code paths, add matching smoke scripts under `scripts/` and mention how to trigger them in `README.md` so remote agents can run verifications end-to-end.
- Update `docs/plan/` when creating iteration roadmaps and close the loop by referencing the plan in the corresponding specs and commits (`spec:<topic>` tag).

## Execution Playbook
- Install LuaRocks + Busted (`luarocks --lua-version=5.1 --lua-interpreter=luajit install busted --local`) before running specs locally or via remote agents.
- Run the full spec suite with `./scripts/test.sh`; use `./scripts/test-network.sh` for focused networking checks and pass explicit spec paths for tight loops.
- Build artifacts with `./scripts/build.sh` (Bob wrapper) and use `./scripts/bob-smoke.sh` to exercise Bob's `resolve`, `build`, and `bundle` commands in sequence.
- Override network ports per environment through `[network] discovery_port` in `game.project` when orchestrating multi-agent or multi-device test runs.

## Defold 1.11 Quick-Test Playbook
- When wiring new GUI components into a collection, use literal component ids (e.g. `/main/ui.gui`) and avoid escaped quotes or Defold will reject the collection.
- Stick to `/builtins/fonts/default.font` for UI text; older Defold runtimes ship without `system_font.font`.
- Post messages with fully qualified URLs such as `main:/go#ui` ↔ `main:/go#main` to avoid "socket ''" errors when components initialize.
- Give the GUI input focus (and drop it from the script) so buttons receive touch events; mixing both can swallow clicks.
- In Defold 1.11 `gui.pick_node` expects scalar `x, y` arguments—wrap touches with `vmath.vector3` only if you pass the individual components.
- Avoid `gui.set_text_align`—it was added after 1.11. Use pivots and padding instead when formatting text nodes.
- When adding UDP ping/pong utilities, bind the server to a fixed port, compute a subnet broadcast from `socket.dns.toip` (fall back to `255.255.255.255`), and log each send/receive so multi-machine tests can be verified quickly.
- Keep ad-hoc capture folders like `screencaps/` out of version control by updating `.gitignore`.
