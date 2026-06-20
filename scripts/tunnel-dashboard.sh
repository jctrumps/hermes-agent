#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-hermes-01}"
LOCAL_PORT="${LOCAL_PORT:-9119}"
REMOTE_PORT="${REMOTE_PORT:-9119}"

echo "Opening tunnel: http://127.0.0.1:${LOCAL_PORT}"
ssh -L "${LOCAL_PORT}:127.0.0.1:${REMOTE_PORT}" "ubuntu@${HOST}"
