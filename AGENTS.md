# AGENTS.md

## Project purpose

Deploy Hermes Agent on a small Proxmox VM or mini box while using a separate Ollama host for inference.

## Desired style

Follow the same layered pattern as the user's existing homelab repos:

```text
OpenTofu -> VM
Ansible  -> OS + Docker + config
Compose  -> app runtime
Docs     -> runbooks and notes
```

## Important rules

- Do not commit secrets, API keys, `.env`, `terraform.tfvars`, or Ansible vault files.
- Keep Hermes dashboard bound to localhost unless explicit authentication/reverse proxy work is added.
- Keep Ollama on Blade 6 or another model host; do not run Ollama on the mini box for this project.
- Prefer simple, repeatable commands over clever automation.
- Ubuntu 24.04 cloud-init template is the default.
- When documenting WSL usage from `/mnt/c`, use explicit `ANSIBLE_CONFIG` and `-i inventory/hosts.ini` in Ansible commands.
- Prefer WSL/Linux for OpenTofu if Windows Application Control blocks provider executables.

## Repository map

- `opentofu/` provisions the Proxmox VM and writes `ansible/inventory/hosts.ini`.
- `ansible/` configures Ubuntu, Docker, firewall, and the Hermes Compose runtime.
- `docs/` holds operator-facing guides and runbooks.
- `scripts/` holds small local helper scripts only.

## Local-only artifacts

- `opentofu/terraform.tfvars` may contain a Proxmox API token.
- `opentofu/.terraform/` is generated provider/cache content.
- `ansible/group_vars/hermes_vault.yml` contains deployment secrets/placeholders.
- `ansible/inventory/hosts.ini` is generated for the local environment.

Do not copy values from local-only files into examples, docs, tickets, or commits.

## Validation

- OpenTofu changes: run `tofu fmt -check` and `tofu validate` from `opentofu/` when credentials and provider cache are available.
- Ansible changes: run `ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --syntax-check site.yml` from `ansible/` when the inventory exists.
- Markdown-only changes: verify links and keep commands copy/paste friendly.
