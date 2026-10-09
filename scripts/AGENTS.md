# AGENTS.md

## Scope

This directory contains small operator helper scripts.

## Rules

- Scripts should be safe wrappers around documented commands.
- Do not embed secrets, tokens, real private IPs, real hostnames, usernames, or private key paths.
- Use `10.10.10.0/24` for documented example addresses.
- Keep scripts POSIX-shell friendly with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Prefer environment variables for overrides and document them in the script or docs.
- Do not add broad automation that hides OpenTofu or Ansible steps.
- Keep dashboard helpers tunnel-based; do not add scripts that open the Hermes dashboard directly on the LAN.

## Validation

For shell scripts, run syntax checks when Bash is available:

```bash
bash -n scripts/check-ollama.sh
bash -n scripts/tunnel-dashboard.sh
```
