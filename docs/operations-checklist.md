# Operations Checklist

Use this as the short path for routine work.

## Before provisioning

- Confirm the Ubuntu 24.04 cloud-init template exists in Proxmox.
- Confirm the Proxmox API token is present only in `opentofu/terraform.tfvars` or the shell environment.
- Confirm the SSH public key in `terraform.tfvars` matches the private key path used by Ansible.
- Confirm the target VM ID and static IP are unused.
- Confirm Ollama is reachable from the target network.
- Confirm local deployment files were copied from examples and are not tracked by Git.

## Provision

```bash
make infra-init
make infra-plan
make infra-apply
```

## Configure

```bash
cd ansible
cp group_vars/hermes.yml.example group_vars/hermes.yml
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
curl http://10.10.10.20:11434/v1/models
cd /opt/hermes-agent
docker compose ps
```

From your workstation:

```bash
ssh -L 9119:127.0.0.1:9119 ubuntu@hermes-01
```

Open `http://127.0.0.1:9119`.

## Routine update

For the current hash-based domain deployment on an existing VM, use [Deploy the latest dashboard changes](deployment-guide.md#deploy-the-latest-dashboard-changes-to-an-existing-vm). Add `--ask-vault-pass` to the playbook commands below when your local Vault file is encrypted. Rebuild the Hermes image on the VM to pick up upstream auth/throttle changes; reapplying Ansible alone can reuse an existing image.

```bash
cd ansible
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini site.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/status.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/logs.yml
```

## Before exposing anything

For a same-VM Cloudflare Tunnel, keep the dashboard on localhost and follow [Login throttling and bot protection](login-protection.md) for login rate limiting and audit checks. Cloudflare Access remains optional.

- Add authentication or a reverse proxy first.
- Update `docs/security.md`.
- Change `hermes_dashboard_host` and firewall rules only in the same reviewed change.
