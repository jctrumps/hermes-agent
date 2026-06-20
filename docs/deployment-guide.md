# Deployment guide

## Recommended homelab layout

Use the mini box or a small VM for Hermes Agent only.

Use Blade 6 HX5 for Ollama and model inference.

```text
hermes-01 -> http://192.168.86.16:11434/v1 -> ollama-01 / Blade 6
```

## VM sizing

Minimum:

```text
2 vCPU
4 GB RAM
40 GB disk
```

Preferred:

```text
2-4 vCPU
8 GB RAM
60+ GB disk
```

## Pre-flight checks

From the future Hermes VM, verify Ollama is reachable:

```bash
curl http://192.168.86.16:11434/v1/models
```

If that fails, check Ollama bind address and firewall rules on Blade 6.

## Deployment order

1. Provision the VM with OpenTofu.
2. Let cloud-init finish on the VM.
3. Install Ansible collections.
4. Confirm Ansible can ping the VM.
5. Run the Ansible site playbook.
6. Open the dashboard through an SSH tunnel.

## Local files to create

Create these from examples and keep them out of Git:

```bash
cp opentofu/terraform.tfvars.example opentofu/terraform.tfvars
cp ansible/group_vars/hermes_vault.yml.example ansible/group_vars/hermes_vault.yml
```

## Validate before apply

```bash
cd opentofu
tofu fmt -check
tofu validate
tofu plan
```

## Validate Ansible

```bash
cd ansible

eval "$(ssh-agent -s)"
mkdir -p ~/.ssh

cp /mnt/c/Users/<USER>/.ssh/hermes_01_ed25519 ~/.ssh/
chmod 600 ~/.ssh/hermes_01_ed25519

ssh-add ~/.ssh/hermes_01_ed25519

ansible-galaxy collection install -r requirements.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible -i inventory/hosts.ini all -m ping
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --syntax-check site.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini site.yml
```

When running from WSL under `/mnt/c`, pass `ANSIBLE_CONFIG` and `-i` explicitly. WSL can mark Windows-mounted directories as world-writable, which makes Ansible ignore `ansible.cfg` during automatic config discovery.

## After deployment

Check the rendered stack from Ansible:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/status.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/logs.yml
```

Open Hermes in the browser through an SSH tunnel:

```bash
ssh -L 9119:127.0.0.1:9119 ubuntu@hermes-01
```

Then browse to `http://127.0.0.1:9119`.

If `hermes-01` does not resolve from the workstation, use the VM IP address instead.
