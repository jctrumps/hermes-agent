# Deployment guide

## Recommended homelab layout

Use the mini box or a small VM for Hermes Agent only.

Use a separate model host for Ollama and model inference.

```text
hermes-01 -> http://10.10.10.20:11434/v1 -> ollama-01
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
3 vCPU
12 GiB RAM (12288 MiB)
60+ GB disk
```

The OpenTofu defaults and example allocate 3 vCPUs and 12 GiB for browser automation and heavier tool use. An existing deployment uses the `cpu_cores` and `memory_mb` values in its local `opentofu/terraform.tfvars`; see [Resize VM CPUs](runbook.md#resize-vm-cpus) and [Resize VM memory](runbook.md#resize-vm-memory) to apply changes and verify them in the guest. Hosted-model inference still runs at the external provider.

## Pre-flight checks

For hosted models, follow [Hosted model providers](model-providers.md); no Ollama host is required. Provider overrides in the Ansible example now start empty so browser login and Hermes's provider selection can manage the model.

If using Ollama, from the future Hermes VM verify it is reachable:

```bash
curl http://10.10.10.20:11434/v1/models
```

If that fails, check Ollama bind address and firewall rules on the model host.

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
cp ansible/group_vars/hermes.yml.example ansible/group_vars/hermes.yml
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

## Optional domain hosting

Follow [Cloudflare Tunnel hosting](cloudflare-tunnel.md) to publish an HTTPS hostname through a separately installed connector running on the Hermes VM. Set `hermes_dashboard_public_url` and dashboard credentials in local Ansible settings, leaving `hermes_cloudflare_tunnel_enabled: false`. A tunnel token is needed in Ansible only if you choose the optional Compose-managed connector. The dashboard remains on `127.0.0.1:9119`; Hermes's password login protects browser access and Cloudflare Access can be added later.

Use [Dashboard hashes and Ansible Vault](dashboard-auth.md) to generate `hermes_dashboard_password_hash` and encrypt local secrets. Once encrypted, add `--ask-vault-pass` to playbook commands that load the Vault file, including syntax checks and operations playbooks.

## Deploy the latest dashboard changes to an existing VM

Use this path when the VM and inventory already exist. Preserve your local settings rather than copying `.example` files over them. Your local `hermes.yml` needs the full public HTTPS URL, dashboard username, localhost bind, and `hermes_cloudflare_tunnel_enabled: false` for a manually installed connector. Hosted-provider overrides should be empty when using the Hermes provider picker.

Your local `hermes_vault.yml` must contain `hermes_dashboard_password_hash` and the session-signing secret, with the old plaintext `hermes_dashboard_password` removed. Follow [Dashboard hashes and Ansible Vault](dashboard-auth.md) if migration or encryption is not yet complete.

From `ansible/` in WSL/Linux, for an encrypted Vault file:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --ask-vault-pass --syntax-check site.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --ask-vault-pass site.yml
```

Enter the Vault passphrase at the prompt. For a local file that is still plaintext, omit `--ask-vault-pass`. The apply updates the source checkout and rendered configuration. The existing `build: policy` behavior can reuse the old image, so rebuild it on the Hermes VM:

```bash
cd /opt/hermes-agent
docker compose build gateway
docker compose up -d
docker compose ps
docker compose logs --tail=100 dashboard
sudo systemctl status cloudflared --no-pager
curl -I http://127.0.0.1:9119/login
sudo ss -lntp 'sport = :9119'
```

An older image may refuse the new auth configuration until this rebuild completes. Rebuild/updating the image uses the shared data mount and does not require deleting it. Keep your manual `cloudflared` connector configured with `http://127.0.0.1:9119`; no Ansible tunnel token is needed.

Open your public HTTPS URL in a private browser window, confirm a login is required, and use your dashboard username and actual password. Verify a dashboard page and chat session. Check the auth audit log and add the separately configured Cloudflare login rate limit using [Login throttling and bot protection](login-protection.md). The guide also covers client-IP forwarding and optional Bot Fight Mode; Access remains optional.
