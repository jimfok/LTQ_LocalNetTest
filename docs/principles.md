# Engineering Principles

These evergreen guardrails steer implementation choices, regardless of sprint-specific context.

## 1. Spec-First Delivery
- Treat `spec/` as the source of truth for behaviour. New work begins by refining the relevant spec and linking it to commits and tasks (`spec:<topic>` tags).
- Keep specs executable by mirroring the runtime structure under `tests/` and ensuring every scenario in `spec/` maps to at least one automated check.

## 2. Traceable Planning
- Maintain task intent in `plan/TASKS.md`, linking each item to the owning spec and validation commands.
- Reference planning artefacts from commits, docs, and ADRs to ensure future agents can trace decisions end-to-end.

## 3. Deterministic Tooling
- Prefer hermetic scripts under `scripts/` with machine-readable logs (`TRACE|component|action|status`) so local and remote agents share the same execution surface.
- Document required environment setup in `README.md` and keep command entry points stable.

## 4. Modular Runtime & Tests
- Structure production code and tests with shared abstractions (`tests/support/`) to avoid duplication and ease simulator validation.
- Keep fixtures side-effect free; inject dependencies so unit and simulator flows can run in isolation.

## 5. Decision Hygiene
- Record impactful choices as time-phased MADR entries in `docs/ADRs/`. Promote entries from Draft → Trial → Accepted only after stakeholders log `DECISION: ACCEPT <ADR-ID>`.
- Capture follow-up questions or open issues inside the ADR "Consequences" section to guide future updates.

## 6. Network Transparency
- Log network discovery, broadcasting, and join events with explicit payloads to aid debugging across devices.
- Default to safe fallbacks (e.g. broadcast `255.255.255.255`) while allowing overrides via `game.project` configuration.

## 7. Asset Discipline
- Avoid versioning large binaries; document acquisition steps instead.
- Update `.gitignore` whenever new generated artefacts appear in local workflows.
