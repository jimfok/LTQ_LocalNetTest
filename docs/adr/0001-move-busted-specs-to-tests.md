# ADR 0001: Move Busted specs to tests directory

- Status: Accepted
- Date: 2025-09-29
- Spec ID: spec:tests-suite-location

## Context
`docs/spec/` now captures narrative outlines for features and scenarios. Keeping executable Busted suites in `spec/` created friction for tooling and for Qwen 30B hand-offs because the same prefix denoted both documentation and test code. Executors hesitated between `spec/` and `docs/spec/`, and scripts like `./scripts/test.sh` defaulted to the old location.

## Decision
- Relocate every Busted spec helper and suite from `spec/` to `tests/`, mirroring runtime modules (for example, `tests/network` ↔ `src/network`).
- Rename helper requires to `tests.*` (`tests.spec_helper`, `tests.support.network_context`) so packages resolve without `spec/`.
- Update harnesses so `./scripts/test.sh` runs `busted tests` by default and `./scripts/test-network.sh` targets `tests/network`.
- Refresh contributor docs (`README.md`, `AGENTS.md`) to point at the new layout and cross-link to `docs/spec/` for design traces.

## Consequences
- Executors and documenters now have a clear split: `docs/spec/` for intent, `tests/` for runnable specs.
- Existing invocations that referenced `spec/...` must switch to `tests/...`; automation using the old path will fail until updated.
- Future specs must continue tagging commits, docs, and test files with `spec:<topic>` so traceability survives the relocation.
