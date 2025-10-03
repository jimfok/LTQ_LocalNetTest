# Agent Guidelines

> 📌 Start here, then follow the README quick links: [`README.md`](README.md)

## Collaboration Modes

### Mode A — Interactive (IDE / Roo Code / qwen2.5)
1. **Propose Plan** – output ≤8 numbered steps, mapping each step to touched files & tests.
2. **Wait for ACK** – pause until the human replies `ACK step X–Y`.
3. **Apply** – execute only the acknowledged steps; keep diffs small and leave inline TODOs if follow-up is required.
4. **Self-check** – run `just check` and share the final one-line summary.
5. **Summarize** – append findings to the current `plan/sprint-<N>.md` under **Coding Findings**.
6. **Failure handling** – stop immediately if a command fails, show minimal logs, and recommend a rollback.

### Mode B — Batch (Codex Web UI)
- Deliver a complete batch with:
  - **Execution Plan (brief)** – list actions and reasoning.
  - **Changes** – include the unified diff or explicit file blocks for every edit.
  - **Tests** – add or update specs with visible diffs.
  - **Docs** – update `spec/` when behaviour changes, `docs/ADRs/` (Draft/Trial), and `docs/QA/*` summaries when generated.
  - **Commands** – provide one shell block to reproduce locally (must end with `just check`).
  - **Rollback** – describe how to revert (files/commands).

Use Mode A when working through an IDE or Roo Code. Use Mode B from web chat or other batch tooling.

## Repository Guardrails
- This repository does **not** use Git LFS. Never commit files ≥100 MB. Validate with `git ls-files --stage` / `git status --short` and `git ls-files -z | xargs -0 ls -lh` before committing.
- Keep generated or binary assets out of version control; update `.gitignore` for any new build artefacts.
- Large tools (editors, SDKs, archives) should stay outside the repo—re-download or document external storage as needed.
- Branches created by agents should follow `feature/<topic>`.

## Information Architecture
- **spec/** – authoritative requirements, state machines, and acceptance criteria (WHAT).
- **plan/** – planning artefacts, roadmaps, sprint scopes, and `plan/TASKS.md` (WHEN/WHO).
- **src/** & **tests/** – implementation and verification (HOW). Mirror structures for discoverability.
- **docs/ADRs/** – time-phased MADR-style records explaining major decisions (WHY) ordered chronologically.
- **docs/principles.md** – evergreen guardrails guiding implementation.
- Cross-link specs, plans, ADRs, and commits using `spec:<topic>` tags for traceability.

## Practice Tips (Day-to-Day)
1. **Start from Spec** – confirm relevant requirements in `spec/` before editing code or tests.
2. **Pick a Task** – select work from `plan/TASKS.md`; each entry links to spec IDs and exit criteria.
3. **Choose Mode** – IDE → Mode A, web chat → Mode B.
4. **Check Status** – run `just check` periodically to execute lint/tests/build and refresh `docs/QA/*`.
5. **Summarize Findings** – append 3–5 bullets to `plan/sprint-<N>.md` under **Coding Findings**.
6. **Decisions** – draft ADRs as **Draft/Trial**; only mark **Accepted** after a recorded `DECISION: ACCEPT <ADR-ID>`.
7. **Push Policy** – use forks for remote operations; keep instructions agent-executable.

## Spec-Driven Project Layout
- Maintain executable specs that mirror runtime modules (`tests/network` ↔ `src/network`).
- Extend helpers under `tests/support/` instead of duplicating setup logic; keep fixtures side-effect free and document usage at the top of each helper.
- Record cross-module behaviour in `spec/` and link related tests plus tasks in `plan/`.
- When adding new root-level entry points, pair them with smoke scripts under `scripts/` and document invocation in `README.md`.
- Update plans when creating iteration roadmaps; reference the plan and spec IDs in commits via `spec:<topic>`.

## Execution Playbook
- Install LuaRocks + Busted (`luarocks --lua-version=5.1 --lua-interpreter=luajit install busted --local`) before running specs.
- Run the full suite with `./scripts/test.sh`; use `./scripts/test-network.sh` for network-focused checks.
- Build via `./scripts/build.sh` (Bob wrapper) and smoke Bob with `./scripts/bob-smoke.sh` (resolve → build → bundle).
- Configure discovery ports per environment through `[network] discovery_port` in `game.project` when orchestrating multi-agent tests.

## GitHub Workflows
- The repository intentionally excludes GitHub Actions—do not add `.github/workflows/*.yml` without explicit owner approval.
- If CI is required, confirm expectations with the owner before modifying workflow configuration.
- Document local validation steps in `README.md`, `spec/`, or `plan/` instead of relying on hosted workflows.

## Defold 1.11 Quick-Test Playbook
- Use literal component IDs (e.g. `/main/ui.gui`) when wiring GUI components into collections.
- Prefer `/builtins/fonts/default.font` for UI text; older runtimes omit `system_font.font`.
- Post messages with fully qualified URLs (e.g. `main:/go#ui`) to avoid empty-socket errors during component init.
- Ensure the GUI holds input focus so buttons receive touch events; release focus from scripts to prevent swallowed clicks.
- `gui.pick_node` expects scalar `x, y` arguments in Defold 1.11—wrap touches with `vmath.vector3` only when passing components individually.
- Avoid `gui.set_text_align` (added after 1.11); rely on pivots and padding for formatting.
- For UDP ping/pong utilities, bind servers to fixed ports, compute subnet broadcasts from `socket.dns.toip` (fallback `255.255.255.255`), and log each send/receive.
- Keep temporary capture folders like `screencaps/` out of version control via `.gitignore` updates.
