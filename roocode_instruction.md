# Roo Code Contributor Instructions

## Scope of Work
When implementing TODOs or feature requests, keep changes within the following directories unless the task owner explicitly expands the scope:
- `src/` – core Lua modules and reusable automation helpers.
- `main/` – Defold collection scripts, GUI logic, and entry point behaviours.
- `scripts/` – command-line helpers and reproducible automation entrypoints.
- `tests/` – Busted specs, fixtures, and support utilities that verify behaviour.
- `assets/` – JSON, Lua, or other lightweight configuration assets that ship with the runtime (do not add large binaries).

## Folders Off-Limits Without Approval
Do **not** modify the items below unless the maintainer requests it in the task description:
- `docs/` – planning notes, specs, and historical documentation.
- Any `AGENTS.md` file – these documents define process guardrails.
- Repository metadata and environment settings: `.gitignore`, `.editorconfig`, `game.project`, project configuration under `.github/`, and container/toolchain descriptors.
- `README.md` and other top-level guidance files unless the task is explicitly documentation-focused.
- Third-party vendored content under `input/` or similar directories.

## Coding Practices
- Follow the spec-driven workflow: align new code with the relevant spec ID (`spec:<topic>`) in comments, commit messages, and test names where appropriate.
- Prefer extending existing helpers instead of duplicating logic; keep functions small, composable, and covered by tests.
- Maintain consistent Lua style: use clear names, early returns for error cases, and avoid global state unless the module contract requires it.
- Keep runtime logging structured (e.g., `TRACE|component|action|status`) rather than ad-hoc prints, and clean up temporary debugging output before committing.
- Update or add tests in `tests/` whenever behaviour changes, and run `./scripts/test.sh` to validate before hand-off.

## Change Logging
Every coding session must append a summary line to `roocode_changes.log` (create the file if it does not exist) using the format below:
```
YYYY-MM-DD HH:MM TZ | actor | area_touched | short_summary | tests_run
```
Example:
```
2024-06-12 14:05 UTC | roo-coder | src/network | Implement UDP broadcast retry | ./scripts/test.sh
```
Keep the log in chronological order and include any skipped or failed tests in the `tests_run` field for traceability.
