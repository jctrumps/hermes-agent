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
curl -fsS http://192.168.86.16:11434/v1/models | jq .
```

## Working notes

- Use explicit `ANSIBLE_CONFIG="$PWD/ansible.cfg"` and `-i inventory/hosts.ini` from WSL under `/mnt/c`.
- Keep the dashboard bound to `127.0.0.1`; use SSH tunneling for browser access.
- Keep Ollama on Blade 6 or another model host, not on the Hermes VM.
- Do not commit `opentofu/terraform.tfvars`, `ansible/group_vars/hermes_vault.yml`, or `ansible/inventory/hosts.ini`.
