# Welcome to Defold

This project was created from the "mobile" project template. This means that the settings in ["game.project"](defold://open?path=/game.project) have been changed to be suitable for a mobile game:

- The screen size is set to 640x1136
- The projection is set to Fixed Fit
- Orientation is fixed vertically
- Android and iOS icons are set
- Mouse click/single touch is bound to action "touch"
- A simple script in a game object is set up to receive and react to input
- Accelerometer input is turned off (for better battery life)

[Build and run](defold://build) to see it in action. You can of course alter these settings to fit your needs.

Check out [the documentation pages](https://defold.com/learn) for examples, tutorials, manuals and API docs.

If you run into trouble, help is available in [our forum](https://forum.defold.com).

Happy Defolding!

---

### Local network discovery

The file `src/network/discovery.lua` sets up a multicast UDP listener and broadcasts a `HELLO` message with the device ID and model. This allows instances of the game on the same network to announce themselves and detect others. `main/main.script` shows how the module is initialized and used each frame.

## Spec-driven architecture

- Network code now lives under `src/network`, making it reusable from both runtime scripts and unit specs.
- `main/main.script` creates a `Discovery` instance, which exposes `listen`, `broadcast_hello`, `receive`, and `close` instance methods.
- Behavioural specs reside in `spec/network` and assume the [Busted](https://lunarmodules.github.io/busted/) runner (`luarocks install busted` then `busted spec`).
- Specs rely on dependency injection; production code uses Defold's `socket`, `json`, and `sys` while tests stub these interfaces.
- Override the UDP port via `game.project` (add `[network]` → `discovery_port = 53317`, for example) to run multiple instances on the same machine.
