#!/usr/bin/env bash
set -euo pipefail

OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://10.10.10.20:11434/v1}"

echo "Checking Ollama at: ${OLLAMA_BASE_URL}/models"
curl -fsS "${OLLAMA_BASE_URL}/models" | jq .
