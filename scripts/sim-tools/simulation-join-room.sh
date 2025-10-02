#!/usr/bin/env bash
# TRACE|sim-tools|simulation-join-room|ready
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HARNESS="${REPO_ROOT}/src/sim-tools/simulation_join_room.lua"

LUA_BIN=${LUA_BIN:-}
if [[ -z "${LUA_BIN}" ]]; then
    if command -v luajit >/dev/null 2>&1; then
        LUA_BIN="luajit"
    else
        LUA_BIN="lua"
    fi
fi

exec "${LUA_BIN}" "${HARNESS}" "$@"
