# Session Wrap-Up

Current handoff notes after the first successful deployment session.

## Completed

- OpenTofu configuration validated successfully.
- Windows Application Control blocked the Windows Proxmox provider binary, so WSL/Linux is the practical OpenTofu path.
- OpenTofu generated `ansible/inventory/hosts.ini`.
- Ansible reached `hermes-01` successfully with `ping: pong`.
- Ansible syntax check passed.
- The Ansible callback setting was updated away from the removed `community.general.yaml` callback.
- The Hermes environment template now defaults `OPENAI_API_KEY` to `ollama-local` for local Ollama deployments.
- The Hermes Docker image build completed. The Docker Bake/buildx message was only a warning.
- The site playbook completed successfully.
- Public-repository cleanup converted local Ansible settings to `ansible/group_vars/hermes.yml.example` and ignored the real `hermes.yml`.
- Public examples now use `10.10.10.0/24` addresses.
- Tracked content and filenames were checked for local names, aliases, usernames, and machine names.

## Current access path

Start an SSH tunnel from the workstation:

```bash
ssh -L 9119:127.0.0.1:9119 ubuntu@hermes-01
```

Open Hermes in the browser:

```text
http://127.0.0.1:9119
```

If `hermes-01` does not resolve, use the Hermes VM IP address in the SSH command.

## Next session

Check status first:

```bash
cd /mnt/c/projects/hermes-agent/ansible
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/status.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/logs.yml
```

Check Ollama reachability from the Hermes VM:

```bash
ssh ubuntu@hermes-01
curl -fsS http://10.10.10.20:11434/v1/models | jq .
```

## Working notes

- VM CPUs now default to 3 vCPUs in OpenTofu and its example, and the local `cpu_cores` setting was updated for heavier browser/tool testing. The live change still requires plan/apply and guest verification; it can be applied with the pending memory resize. See [Resize VM CPUs](runbook.md#resize-vm-cpus).

- VM memory now defaults to 12 GiB (`12288` MiB) in OpenTofu and its example; the local memory setting was updated for testing heavier browser/tool workloads. The VM resize still requires an OpenTofu plan/apply and guest verification. See [Resize VM memory](runbook.md#resize-vm-memory).

- The publication audit found that `ansible/group_vars/hermes.yml` is still Git-tracked despite the ignore rule. The initial commit also retains local network/site-specific data in configuration and docs. Stop tracking the local file and sanitize publication history before a public push; see [Public repository checklist](public-repo-checklist.md). The audit did not commit, push, untrack files, or rewrite history. GitHub visibility could not be verified with the unauthenticated local CLI.

- Login protection is documented in [Login throttling and bot protection](login-protection.md): upstream Hermes's 10-attempt/60-second per-IP window, a separately configured Cloudflare 5-request/10-second login burst rule, optional bot detection, and auth audit/client-IP verification. The inspected behavior still needs verification on the deployed image; no Cloudflare security rule has been created by this repository.
- The next apply/rebuild sequence is in [Deploy the latest dashboard changes](deployment-guide.md#deploy-the-latest-dashboard-changes-to-an-existing-vm). Current repository work is ready for operator deployment; no new live deployment has been performed during this documentation update.

- Same-VM Cloudflare Tunnel hosting is configured in the repository; see [Cloudflare Tunnel hosting](cloudflare-tunnel.md). The guide defaults to a separately installed/manual connector (`hermes_cloudflare_tunnel_enabled: false`), requiring no tunnel token in Ansible. Hermes's app login is required; Cloudflare Access is optional and can be added later. Live activation still requires local public URL/dashboard credentials, tunnel/DNS configuration, and an Ansible apply. Existing images should be rebuilt for current upstream dashboard auth support.
- Dashboard deployment now requires `hermes_dashboard_password_hash` and rejects a legacy plaintext password setting. [Dashboard hashes and Ansible Vault](dashboard-auth.md) covers the interactive hash helper, migration, local encryption, and `--ask-vault-pass`. Local secrets have not been migrated/encrypted automatically; those steps require the operator's chosen password and Vault passphrase.
- Ansible provider overrides now default to empty and omit unset values from the container environment. [Hosted model providers](model-providers.md) covers ChatGPT/Codex browser login and OpenCode Zen; Ollama remains an optional separate-host setup. Provider login and live model use still need to be completed on the deployed VM.

- Use explicit `ANSIBLE_CONFIG="$PWD/ansible.cfg"` and `-i inventory/hosts.ini` from WSL under `/mnt/c`.
- Keep the dashboard bound to `127.0.0.1`; use SSH tunneling for browser access.
- Keep Ollama on a separate model host, not on the Hermes VM.
- Use `10.10.10.0/24` for example IP addresses in public docs.
- Do not publish personal names, aliases, usernames, machine names, or site-specific labels.
- Do not commit `opentofu/terraform.tfvars`, `ansible/group_vars/hermes.yml`, `ansible/group_vars/hermes_vault.yml`, or `ansible/inventory/hosts.ini`.
- Run the checks in `docs/public-repo-checklist.md` before publishing.
