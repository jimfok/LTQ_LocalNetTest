# ADR 0001: Move Busted specs to tests directory

- Status: Accepted
- Deciders: Core maintainers
- Date: 2025-09-29
- Tags: spec:tests-suite-location

## Status History
| Phase | Date | Notes |
| --- | --- | --- |
| Draft | 2025-09-28 | Documented tooling friction caused by mixed spec + test hierarchy. |
| Trial | 2025-09-29 | Ran `./scripts/test.sh` from relocated tree to validate harness updates. |
| Accepted | 2025-09-29 | `DECISION: ACCEPT ADR-0001` recorded after confirming team-wide alignment. |

## Context and Problem Statement
`spec/` now captures narrative outlines for features and scenarios. Housing executable Busted suites in the same tree confused both humans and automation: identical prefixes hid whether a file was documentation or runnable code, and helpers such as `tests/support/network_context.lua` were difficult to discover. Scripts like `./scripts/test.sh` defaulted to the legacy path, leading to drift between spec intent and verification.

## Decision Drivers
1. Preserve a single source of truth for requirements under `spec/`.
2. Improve discoverability by mirroring runtime modules (`tests/network` ↔ `src/network`).
3. Keep automation entry points stable for agents and CI scripts.

## Considered Options
1. **Maintain mixed tree** – no relocation; continue documenting the split manually. Rejected due to persistent confusion.
2. **Introduce subfolders under `spec/`** – place executable specs in `spec/tests/`. Rejected because it still couples documentation and code.
3. **Relocate tests to top-level `tests/`** – mirror runtime layout and retarget harnesses. Chosen option.

## Decision Outcome
- Move every Busted helper and suite from `spec/` to `tests/`, matching runtime namespaces.
- Update `require` paths to `tests.*` (for example, `tests.spec_helper`, `tests.support.network_context`).
- Update harnesses so `./scripts/test.sh` executes `busted tests` and `./scripts/test-network.sh` targets `tests/network` by default.
- Refresh contributor docs (`README.md`, `AGENTS.md`) to explain the new split and cross-link specs for intent.

## Consequences and Follow-up
- Executors and documenters now have a clear contract: `spec/` = intent, `tests/` = verification.
- Any automation that referenced `spec/...` must update paths or will fail. Track outstanding updates in `plan/TASKS.md`.
- Continue tagging commits, docs, and test files with `spec:<topic>` to keep traceability across the reorganised tree.

## References
- [`spec/tests-suite-location.md`](../../spec/tests-suite-location.md) – authoritative requirements for the suite layout.
- [`README.md`](../../README.md) – onboarding notes and execution commands for the relocated tests.
