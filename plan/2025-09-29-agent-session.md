# Plan Log 2025-09-29
- spec:tests-suite-location

## Summary
- Clarified AGENT guidance to align with updated README and Qwen 30B executor workflows.
- Relocated Busted specs and helpers from `spec/` to `tests/`, updating harness scripts and documentation.
- Captured the structural shift in `docs/ADRs/0001-move-busted-specs-to-tests.md` and verified the suite with `./scripts/test.sh`.
- Created branch `feature/tests-relocation` for ongoing work.

## Follow-ups
- Update any external automation still invoking `busted spec/...` paths.
- Ensure new specs include `spec:<topic>` breadcrumbs linking docs, tests, and commits.
