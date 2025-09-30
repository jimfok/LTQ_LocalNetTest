#!/usr/bin/env bash
set -euo pipefail

# spec:sim-tools run-room-server placeholder
#
# Future command flow:
#   lua src/sim-tools/cli.lua simulation-created-room "${@}" \
#       --duration "${DURATION}" --discovery-port "${PORT}" --log-level TRACE
#
# This script remains an echo stub until the CLI is implemented so downstream
# agents know which entrypoint to invoke without triggering missing modules.
echo "sim-tools server harness placeholder: CLI wiring pending"
