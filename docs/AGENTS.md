# AGENTS.md

## Scope

This directory contains operator documentation for deploying and running Hermes Agent.

## Style

- Keep docs direct and command-oriented.
- Prefer short sections with commands that can be pasted as-is.
- Use placeholders like `<HERMES_VM_IP>` instead of real secrets or local-only values.
- Use `10.10.10.0/24` for example IP addresses.
- Do not include real local IPs, hostnames, Windows usernames, API tokens, SSH keys, or inventory contents.
- Keep the layered mental model visible: OpenTofu, Ansible, Compose, docs.
- Do not document exposing the dashboard publicly unless the repo also adds authentication or a reverse proxy.
- For Ansible commands from WSL under `/mnt/c`, show explicit `ANSIBLE_CONFIG` and `-i inventory/hosts.ini`.
- For browser access, document SSH tunneling to `127.0.0.1:9119` rather than opening the dashboard port.

## Required updates

When adding or renaming docs, update `docs/README.md`.

When changing defaults in OpenTofu or Ansible, update the relevant deployment, security, and runbook notes in the same change.

When a deployment session reaches a useful stopping point, update `docs/session-wrap-up.md` with the current handoff state.

When preparing for public repository publication, update `docs/public-repo-checklist.md` if any local-only file patterns change.
