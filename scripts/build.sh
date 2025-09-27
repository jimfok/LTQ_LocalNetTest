#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOB_JAR="$ROOT_DIR/tools/bob.jar"

if [ ! -f "$BOB_JAR" ]; then
  echo "Expected Bob jar at $BOB_JAR but it was not found." >&2
  exit 1
fi

if ! command -v java >/dev/null 2>&1; then
  echo "Java runtime not found; install JDK 21+ to use Bob." >&2
  exit 1
fi

cd "$ROOT_DIR"

ARGS=()
if [ "$#" -eq 0 ]; then
  ARGS=(--variant debug build)
else
  ARGS=("$@")
fi

# Allow callers to prepend extra arguments via the BOB_OPTS environment variable.
if [ -n "${BOB_OPTS:-}" ]; then
  # shellcheck disable=SC2206
  ARGS=(${BOB_OPTS} "${ARGS[@]}")
fi

exec java -jar "$BOB_JAR" "${ARGS[@]}"
