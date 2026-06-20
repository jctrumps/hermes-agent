# Project Review

Reviewed repository shape and defaults for the Hermes Agent homelab deployment.

## What looks right

- The project follows the intended layered pattern: OpenTofu, Ansible, Compose, and docs.
- Hermes is deployed separately from Ollama, keeping inference on the model host.
- The dashboard is localhost-only by default.
- Secrets and local environment files are ignored by `.gitignore`.
- The Ansible roles are small and ordered clearly.
- The Compose runtime is rendered from Ansible instead of being hand-edited on the VM.
- The first deployment completed successfully after WSL/OpenTofu and Ansible callback fixes.

## Local artifacts to protect

- `opentofu/terraform.tfvars` exists locally and may contain a Proxmox API token.
- `opentofu/.terraform/` exists locally and is generated provider/cache content.
- `ansible/group_vars/hermes_vault.yml`, when created, must stay local.
- `ansible/inventory/hosts.ini` is generated and should not be treated as portable project source.

## Added safeguards

- Added a `.gitignore` entry for the generated Ansible inventory.
- Added scoped `AGENTS.md` files so future agent work preserves project boundaries.
- Added docs for architecture, operations, troubleshooting, backup/restore, and model-host expectations.

## Recommended next checks

Run these after local credentials and inventory are ready:

```bash
cd opentofu
tofu fmt -check
tofu validate
```

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --syntax-check site.yml
```

If the deployment already exists, also run:

```bash
cd ansible
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/status.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/logs.yml
```
