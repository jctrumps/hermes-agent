# hermes-agent

Repeatable Hermes Agent deployment for a Proxmox VE homelab using OpenTofu, Ansible, and Docker Compose.

This project is designed for the split AI layout:

```text
Mini box / small VM
└── hermes-agent
    ├── Hermes gateway
    ├── Hermes dashboard, localhost-only by default
    └── connects to Ollama on a separate model host

Model host
└── ollama
    └── serves local models on http://10.10.10.20:11434/v1
```

## Architecture

```text
OpenTofu -> creates the Proxmox VM
Ansible  -> configures Ubuntu, Docker, firewall, directories, and Compose files
Compose  -> builds/runs Hermes Agent from the upstream NousResearch repository
Docs     -> deployment and operations notes
```

## Default target

| Setting | Value |
|---|---|
| Repo | `hermes-agent` |
| VM name | `hermes-01` |
| OS | Ubuntu Server 24.04 LTS |
| Template | `ubuntu-2404-cloudinit` |
| App path | `/opt/hermes-agent` |
| Source path | `/opt/hermes-agent/src` |
| Data path | `/srv/hermes` |
| Ollama API | `http://10.10.10.20:11434/v1` example |
| Dashboard | localhost-only on the Hermes VM |

## Quick start

### 1. Provision the VM

```bash
cd opentofu
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

tofu init
tofu plan
tofu apply
```

OpenTofu writes the Ansible inventory here:

```text
ansible/inventory/hosts.ini
```

### 2. Configure and deploy Hermes

```bash
cd ../ansible
cp group_vars/hermes.yml.example group_vars/hermes.yml
cp group_vars/hermes_vault.yml.example group_vars/hermes_vault.yml
nano group_vars/hermes.yml
nano group_vars/hermes_vault.yml

ansible-galaxy collection install -r requirements.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible -i inventory/hosts.ini all -m ping
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini site.yml
```

When running Ansible from WSL under `/mnt/c`, always pass `ANSIBLE_CONFIG` and `-i inventory/hosts.ini` explicitly. Otherwise Ansible can ignore `ansible.cfg` because Windows-mounted directories appear world-writable.

### 3. Connect to Hermes

The dashboard is intentionally bound to `127.0.0.1` on the Hermes VM. Use an SSH tunnel:

```bash
ssh -L 9119:127.0.0.1:9119 ubuntu@hermes-01
```

Then open:

```text
http://127.0.0.1:9119
```

For domain access, set a public HTTPS URL and dashboard credentials, then configure a Cloudflare Tunnel connector on the Hermes VM. Leave `hermes_cloudflare_tunnel_enabled: false` for a manually installed connector; that flag controls only the project's optional Compose connector. See [Cloudflare Tunnel hosting](docs/cloudflare-tunnel.md) for application variables, optional Cloudflare Access, and the tunnel origin settings. [Dashboard hashes and Ansible Vault](docs/dashboard-auth.md) explains deploying only a password hash and encrypting local secrets.

Provider overrides start empty so Hermes can manage ChatGPT/Codex browser login or OpenCode Zen directly. See [Hosted model providers](docs/model-providers.md). For future Ollama use, enable the commented model-host settings in the examples and follow [Model host](docs/model-host.md).

### 4. Confirm Hermes can reach Ollama

From the Hermes VM:

```bash
curl http://10.10.10.20:11434/v1/models
```

## Makefile helpers

```bash
make infra-init
make infra-plan
make infra-apply
make ping
make app
make deploy
```

## Security defaults

- Hermes dashboard stays localhost-only.
- Optional domain hosting uses Cloudflare Tunnel and Hermes's scrypt-backed username/password login; Cloudflare Access can be added later.
- Hermes data lives under `/srv/hermes`.
- Secrets are kept out of Git.
- Local deployment settings are copied from `.example` files and ignored by Git.
- UFW allows SSH and optionally allows only local/tunnel access to dashboard.
- Ollama should remain LAN-only and ideally firewall-limited to trusted client VMs.

## Public repository safety

- Examples use `10.10.10.0/24` addresses only.
- Do not commit `terraform.tfvars`, `ansible/group_vars/hermes.yml`, Ansible vault files, generated inventories, OpenTofu state, or `.env` files.
- See `docs/public-repo-checklist.md` before publishing or pushing changes.

## Notes

Hermes Agent changes quickly. This project builds the Docker image from the upstream `NousResearch/hermes-agent` repository instead of assuming a stable public container image.

See `docs/session-wrap-up.md` for the current deployed-state handoff notes.
