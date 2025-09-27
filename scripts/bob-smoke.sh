#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/bob-smoke.sh [--platform <target>] [--bundle-output <dir>] [additional bob options]

Runs Defold's Bob tool through resolve → build → bundle to catch early integration issues.

Options:
  --platform <target>      Explicit Bob platform (e.g. x86_64-macos, arm64-macos, x86_64-win32, arm64-ios). Defaults to host platform.
  --bundle-output <dir>    Where bundle artifacts are written (default: build/bundle-<platform>).
  -h, --help               Show this help and exit.

Any extra flags are forwarded to Bob ahead of all commands (for example: --variant release).
USAGE
}

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

PLATFORM=""
BUNDLE_OUT=""
EXTRA_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --platform)
      if [ $# -lt 2 ]; then
        echo "--platform expects an argument" >&2
        exit 1
      fi
      PLATFORM="$2"
      shift 2
      ;;
    --bundle-output)
      if [ $# -lt 2 ]; then
        echo "--bundle-output expects an argument" >&2
        exit 1
      fi
      BUNDLE_OUT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

if [ -z "$PLATFORM" ]; then
  uname_s="$(uname -s)"
  uname_m="$(uname -m)"
  case "$uname_s" in
    Darwin)
      if [ "$uname_m" = "arm64" ]; then
        PLATFORM="arm64-macos"
      else
        PLATFORM="x86_64-macos"
      fi
      ;;
    Linux)
      if [ "$uname_m" = "aarch64" ]; then
        PLATFORM="arm64-linux"
      else
        PLATFORM="x86_64-linux"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      PLATFORM="x86_64-win32"
      ;;
    *)
      echo "Unable to infer Bob platform for $uname_s/$uname_m; please supply --platform." >&2
      exit 1
      ;;
  esac
fi

if [ -z "$BUNDLE_OUT" ]; then
  BUNDLE_OUT="$ROOT_DIR/build/bundle-$PLATFORM"
fi

mkdir -p "$BUNDLE_OUT"

COMMON_ARGS=("java" "-jar" "$BOB_JAR" "--root" "$ROOT_DIR" "--platform" "$PLATFORM")

if [ -n "${BOB_OPTS:-}" ]; then
  # shellcheck disable=SC2206
  EXTRA_ARGS+=(${BOB_OPTS})
fi

run_bob() {
  local command="$1"
  shift
  if [ $# -gt 0 ]; then
    echo "▶ bob $command $*" >&2
  else
    echo "▶ bob $command" >&2
  fi
  local bob_cmd=("${COMMON_ARGS[@]}")
  if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then
    bob_cmd+=("${EXTRA_ARGS[@]}")
  fi
  if [ $# -gt 0 ]; then
    bob_cmd+=("$@")
  fi
  bob_cmd+=("$command")
  "${bob_cmd[@]}"
}

run_bob resolve
run_bob build --archive
run_bob bundle --archive --bundle-output "$BUNDLE_OUT"

echo "✔ Bob resolve/build/bundle completed for platform $PLATFORM" >&2
