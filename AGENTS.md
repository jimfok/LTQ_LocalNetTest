# Agent Guidelines

- Hard requirement: this repository does not use Git LFS. Do not commit or push any file that is 100 MB or larger. Run `git ls-files --stage` / `git status --short` and check sizes (e.g. `git ls-files -z | xargs -0 ls -lh`) before committing.
- If you introduce new generated or binary assets, add them to `.gitignore` instead of versioning them, and ensure existing ignores stay intact.
- Prefer keeping large build artifacts (editors, SDKs, archives) out of the repo; store them in release storage or re-download on demand.
- When creating branches from the Codex CLI agent, use the naming pattern `feature/<topic>` to keep automation and reviews consistent.

## Defold 1.11 quick-test playbook

- When wiring new GUI components into a collection, use literal component ids (e.g. `/main/ui.gui`) and avoid escaped quotes or Defold will reject the collection.
- Stick to `/builtins/fonts/default.font` for UI text; older Defold runtimes ship without `system_font.font`.
- Post messages with fully qualified URLs such as `main:/go#ui` ↔ `main:/go#main` to avoid "socket ''" errors when components initialize.
- Give the GUI input focus (and drop it from the script) so buttons receive touch events; mixing both can swallow clicks.
- In Defold 1.11 `gui.pick_node` expects scalar `x, y` arguments—wrap touches with `vmath.vector3` only if you pass the individual components.
- Avoid `gui.set_text_align`—it was added after 1.11. Use pivots and padding instead when formatting text nodes.
- When adding UDP ping/pong utilities, bind the server to a fixed port, compute a subnet broadcast from `socket.dns.toip` (fall back to `255.255.255.255`), and log each send/receive so multi-machine tests can be verified quickly.
- Keep ad-hoc capture folders like `screencaps/` out of version control by updating `.gitignore`.
