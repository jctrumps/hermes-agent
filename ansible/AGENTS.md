# AGENTS.md

## Scope

This directory configures the Hermes VM after OpenTofu creates it.

## Rules

- Do not commit `group_vars/hermes_vault.yml` or any rendered `.env` file.
- Keep `hermes_dashboard_host` set to `127.0.0.1` unless authentication or a reverse proxy is added in the same change.
- Keep Ollama external to this VM. Do not add an Ollama role or local model runtime here.
- Keep roles small and layered: `base`, `docker`, `hermes`, then `firewall`.
- Prefer idempotent Ansible modules over shell commands.
- Use Ubuntu 24.04 assumptions unless the OpenTofu template changes.
- Keep `stdout_callback = default` and `callback_result_format = yaml`; do not reintroduce the removed `community.general.yaml` callback.
- When documenting or running from WSL under `/mnt/c`, include explicit `ANSIBLE_CONFIG="$PWD/ansible.cfg"` and `-i inventory/hosts.ini`.
- For local Ollama, `hermes_openai_api_key` may safely default to `ollama-local`.

## Variables

- Put non-secret defaults in `group_vars/hermes.yml`.
- Put secrets and API keys only in `group_vars/hermes_vault.yml.example` as placeholders.
- If adding a required variable, document it in the example and relevant docs.

## Validation

Run from this directory when the inventory and vault file exist:

```bash
ansible-galaxy collection install -r requirements.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --syntax-check site.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --syntax-check playbooks/status.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --syntax-check playbooks/logs.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --syntax-check playbooks/restart.yml
```
