# Operations Checklist

Use this as the short path for routine work.

## Before provisioning

- Confirm the Ubuntu 24.04 cloud-init template exists in Proxmox.
- Confirm the Proxmox API token is present only in `opentofu/terraform.tfvars` or the shell environment.
- Confirm the SSH public key in `terraform.tfvars` matches the private key path used by Ansible.
- Confirm the target VM ID and static IP are unused.
- Confirm Ollama is reachable from the target network.

## Provision

```bash
make infra-init
make infra-plan
make infra-apply
```

## Configure

```bash
cd ansible
cp group_vars/hermes_vault.yml.example group_vars/hermes_vault.yml
ansible-galaxy collection install -r requirements.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible -i inventory/hosts.ini all -m ping
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini site.yml
```

Use the explicit `ANSIBLE_CONFIG` and `-i` form when running from WSL under `/mnt/c`.

## Verify

```bash
cd ansible
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/status.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/logs.yml
```

From the Hermes VM:

```bash
curl http://192.168.86.16:11434/v1/models
cd /opt/hermes-agent
docker compose ps
```

From your workstation:

```bash
ssh -L 9119:127.0.0.1:9119 ubuntu@hermes-01
```

Open `http://127.0.0.1:9119`.

## Routine update

```bash
cd ansible
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini site.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/status.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/logs.yml
```

## Before exposing anything

- Add authentication or a reverse proxy first.
- Update `docs/security.md`.
- Change `hermes_dashboard_host` and firewall rules only in the same reviewed change.
