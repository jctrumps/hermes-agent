# Troubleshooting

## OpenTofu provider is blocked by Windows Application Control

Symptom from PowerShell:

```text
Error: Failed to load plugin schemas
failed to instantiate provider "registry.opentofu.org/bpg/proxmox"
An Application Control policy has blocked this file.
```

This means Windows blocked the downloaded provider executable under `.terraform/providers/`. The OpenTofu configuration can be valid while `tofu plan` still fails because the provider binary cannot run.

Practical fixes:

- Run OpenTofu from WSL or another Linux host so OpenTofu downloads and runs the Linux provider binary.
- Ask the Windows/App Control administrator to allow the specific provider binary by hash or an approved plugin-cache path.
- If your policy allows unblocked local files, remove the provider cache and reinitialize after unblocking the download location.

WSL path:

```bash
cd /mnt/c/projects/hermes-agent/opentofu
rm -rf .terraform
tofu init
tofu plan
```

Windows allow-list path to review:

```text
opentofu/.terraform/providers/registry.opentofu.org/bpg/proxmox/0.109.0/windows_amd64/terraform-provider-proxmox_v0.109.0.exe
```

If using an approved plugin cache, set it before `tofu init`:

```powershell
$env:TF_PLUGIN_CACHE_DIR = "$env:LOCALAPPDATA\opentofu-plugin-cache"
tofu init
tofu plan
```

## Ansible cannot connect

If running from WSL under `/mnt/c`, Ansible may ignore `ansible.cfg` because Windows-mounted directories can appear world-writable:

```text
Ansible is being run in a world writable directory, ignoring it as an ansible.cfg source.
No inventory was parsed, only implicit localhost is available.
```

Use explicit config and inventory paths:

```bash
cd /mnt/c/projects/hermes-agent/ansible
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible -i inventory/hosts.ini all -m ping
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini site.yml
```

If that still warns or behaves inconsistently, copy or clone the repo inside the WSL filesystem, for example under `~/projects/hermes-agent`, and run Ansible from there.

If the playbook fails with this callback error:

```text
The 'community.general.yaml' callback plugin has been removed.
```

Use the built-in default callback with YAML formatting in `ansible/ansible.cfg`:

```ini
[defaults]
stdout_callback = default
callback_result_format = yaml
```

If the Hermes environment template fails because `hermes_openai_api_key` is undefined, either copy the vault example or rely on the local Ollama default in the template:

```bash
cp ansible/group_vars/hermes.yml.example ansible/group_vars/hermes.yml
cp ansible/group_vars/hermes_vault.yml.example ansible/group_vars/hermes_vault.yml
```

For Ollama, `OPENAI_API_KEY` can be the placeholder value `ollama-local` because Ollama does not require a real OpenAI key.

If Docker Compose warns that Bake is enabled but `buildx` is not installed:

```text
Docker Compose is configured to build using Bake, but buildx isn't installed
```

This is a warning when the task still ends with `changed: [hermes-01]`. The image build succeeded. To remove the warning later, install the Docker buildx package on the Hermes VM if it is available for the Ubuntu release.

Check the generated inventory:

```bash
cat ansible/inventory/hosts.ini
```

Then test SSH directly:

```bash
ssh -i ~/.ssh/hermes_01_ed25519 ubuntu@<HERMES_VM_IP>
```

Common causes:

- VM has not finished cloud-init.
- Static IP or DHCP lease is not what the inventory expects.
- Private key path in `terraform.tfvars` does not exist on this workstation.
- SSH host key changed after rebuilding the VM.

## OpenTofu creates the VM but Ansible inventory is wrong

If using DHCP, `local.ansible_host` falls back to the VM name. Make sure local DNS resolves `hermes-01` or switch to a static `ipv4_address`.

After changing IP settings:

```bash
cd opentofu
tofu apply
```

## Dashboard does not load

Confirm the containers are running:

```bash
make status
make logs
```

Confirm the dashboard is bound on the VM:

```bash
ssh ubuntu@hermes-01
ss -ltnp | grep 9119
```

Open the tunnel from your workstation:

```bash
ssh -L 9119:127.0.0.1:9119 ubuntu@hermes-01
```

Then browse to `http://127.0.0.1:9119`.

## Hermes cannot reach Ollama

From the Hermes VM:

```bash
curl -fsS http://10.10.10.20:11434/v1/models | jq .
```

If that fails, check these on the Ollama host:

- Ollama is listening on the LAN interface, not only `127.0.0.1`.
- Firewall allows TCP `11434` from the Hermes VM IP.
- The model host IP still matches `hermes_openai_base_url`.

## Docker build fails

Check disk space and upstream source state:

```bash
ssh ubuntu@hermes-01
df -h
cd /opt/hermes-agent/src
git status
```

Rebuild manually if needed:

```bash
cd /opt/hermes-agent
docker compose build --no-cache
docker compose up -d
```

## UFW blocks expected access

The intended default is SSH only plus localhost dashboard access through a tunnel.

Check firewall state:

```bash
sudo ufw status verbose
```

Do not open dashboard port `9119` broadly unless authentication or a reverse proxy is added first.
