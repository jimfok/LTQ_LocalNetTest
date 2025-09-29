#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v luarocks >/dev/null 2>&1; then
  echo "luarocks not found in PATH; install LuaRocks before running tests." >&2
  exit 1
fi

# Ensure locally installed rocks (e.g. busted) and binaries are on PATH.
# shellcheck disable=SC2046
eval "$(luarocks --lua-version=5.1 path --bin)"

if ! command -v busted >/dev/null 2>&1; then
  echo "busted not found; run 'luarocks install busted --local' first." >&2
  exit 1
fi

cd "$ROOT_DIR"

if [ $# -gt 0 ]; then
  exec busted "$@"
else
  exec busted tests
fi
