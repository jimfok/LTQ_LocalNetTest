# Spec: tests suite location
- Spec ID: spec:tests-suite-location
- Status: Accepted
- Linked ADR: docs/ADRs/0001-move-busted-specs-to-tests.md
- Owner: Agent hand-off log 2025-09-29

## Purpose
Ensure all executable Busted suites and helper modules live under `tests/`, leaving `spec/` for narrative outlines. Executor agents should have deterministic entrypoints for running specs and networking smoke tests, and contributor docs must mirror the new layout.

## Preconditions
- Repository contains the network discovery and room server modules under `src/network`.
- Tooling scripts `./scripts/test.sh` and `./scripts/test-network.sh` exist.
- Documentation directories `README.md`, `AGENTS.md`, and `plan/` are in place.

## Scenarios

### S1: Busted runner defaults to tests tree
1. Run `./scripts/test.sh` without arguments.
2. Expect it to call `busted tests` and pass when `tests/network/*.lua` executes.

### S2: Focused networking suite targeting tests
1. Run `./scripts/test-network.sh`.
2. Expect it to invoke `./scripts/test.sh tests/network`.
3. Busted should report all networking specs in `tests/network/`.

### S3: Helpers resolved through tests namespace
1. Open `tests/network/discovery_spec.lua` and `tests/network/room_server_spec.lua`.
2. Each file requires `tests.spec_helper` and `tests.support.network_context`.
3. Helpers exist at `tests/spec_helper.lua` and `tests/support/network_context.lua`.

### S4: Documentation cross-links trace the layout
1. `README.md` references behavioural specs residing in `tests/network` and highlights `tests/support` doubles.
2. `AGENTS.md` mirrors the tests directory guidance and references `tests/support` helpers.
3. `plan/2025-09-29-agent-session.md` logs the relocation with the `spec:tests-suite-location` tag.
4. `docs/ADRs/0001-move-busted-specs-to-tests.md` captures the decision rationale.

### S5: Future specs maintain spec:<topic> breadcrumbs
1. When adding new specs under `tests/`, include the `spec:<topic>` tag in commits, docs, and agent hand-offs.
2. Scenario outlines for those specs live under `spec/` with the same ID for traceability.

## Verification Notes
- Ensure ISO date-stamped plan logs exist for each agent session adjusting the suite layout.
- Remove stale references to the legacy `docs/spec/` path when new modules or scripts are added; cross-reference this spec during reviews.
