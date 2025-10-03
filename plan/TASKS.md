# Active Tasks

This backlog links day-to-day execution to the authoritative specs.

| ID | Spec | Summary | Owner/Mode | Validation |
| --- | --- | --- | --- | --- |
| T-2025-09-29-A | spec:sim-tools | Rebuild join harness (`src/sim-tools/simulation_join_room.lua`, `src/sim-tools/harness/client.lua`) and CLI wrappers. See [plan/tasks/2025-09-29-sim-tools.md](tasks/2025-09-29-sim-tools.md). | Mode A/B | `./scripts/test.sh tests/sim-tools/simulation_join_room_spec.lua` |
| T-2025-09-29-B | spec:sim-tools | Implement host harness + CLI surfaces; capture log schema updates. Track in [plan/tasks/2025-09-29-sim-tools.md](tasks/2025-09-29-sim-tools.md). | Mode B | `./scripts/test.sh tests/sim-tools` |
| T-2025-09-30-A | spec:sim-tools | Align UI terminology and spec language with simulator naming. See [plan/tasks/2025-09-30-sim-tools.md](tasks/2025-09-30-sim-tools.md). | Mode A | Manual UI check + spec diff |
| T-2025-09-30-B | spec:sim-tools | Ship simulator workflow scripts and orchestration notes. See [plan/tasks/2025-09-30-sim-tools.md](tasks/2025-09-30-sim-tools.md). | Mode B | `./scripts/sim-tools/simulation-*.sh --help` + trace review |
| T-2025-09-30-C | spec:sim-tools | Refresh validation checklist and record recent runs. See [plan/tasks/2025-09-30-sim-tools.md](tasks/2025-09-30-sim-tools.md). | Mode A | `./scripts/test.sh tests/sim-tools/simulation_created_room_spec.lua` |

## Usage
1. Pick a task row, confirm the linked spec entry, and decide on Mode A or Mode B.
2. Update the underlying task file with progress notes, validation output, and follow-up TODOs.
3. When complete, cross-reference the closing commit or ADR in the task file and add a note under `plan/sprint-<N>.md`.
