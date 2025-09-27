# Agent Guidelines

- Hard requirement: this repository does not use Git LFS. Do not commit or push any file that is 100 MB or larger. Run `git ls-files --stage` / `git status --short` and check sizes (e.g. `git ls-files -z | xargs -0 ls -lh`) before committing.
- If you introduce new generated or binary assets, add them to `.gitignore` instead of versioning them, and ensure existing ignores stay intact.
- Prefer keeping large build artifacts (editors, SDKs, archives) out of the repo; store them in release storage or re-download on demand.
