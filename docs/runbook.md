# Runbook

If your local `hermes_vault.yml` is encrypted, add `--ask-vault-pass` to the playbook commands below. Use explicit commands instead of the Makefile helpers in that case. See [Dashboard hashes and Ansible Vault](dashboard-auth.md).

## Restart Hermes

```bash
make restart
```

If running Ansible from WSL under `/mnt/c`, use the explicit command instead of relying on `make` or automatic `ansible.cfg` discovery:

```bash
cd /mnt/c/projects/hermes-agent/ansible
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/restart.yml
```

Or on the VM:

```bash
cd /opt/hermes-agent
docker compose restart
```

## View logs

```bash
make logs
```

WSL explicit form:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/logs.yml
```

Or on the VM:

```bash
cd /opt/hermes-agent
docker compose logs -f
```

## Check container status

```bash
make status
```

WSL explicit form:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini playbooks/status.yml
```

Or on the VM:

```bash
cd /opt/hermes-agent
docker compose ps
```

## Check Ollama connectivity

From the Hermes VM:

```bash
curl -fsS http://10.10.10.20:11434/v1/models | jq .
```

## Rebuild after upstream Hermes updates

```bash
cd /opt/hermes-agent/src
git pull

cd /opt/hermes-agent
docker compose build --no-cache
docker compose up -d
```

## SSH tunnel to dashboard

```bash
ssh -L 9119:127.0.0.1:9119 ubuntu@hermes-01
```

Then open:

```text
http://127.0.0.1:9119
```

If `hermes-01` does not resolve, replace it with the Hermes VM IP address.

## Cloudflare domain access

See [Cloudflare Tunnel hosting](cloudflare-tunnel.md) for setup, origin settings, troubleshooting, and rollback. For a manually installed connector, check it on the Hermes VM:

```bash
cd /opt/hermes-agent
docker compose ps dashboard
docker compose logs --tail=100 dashboard
sudo systemctl status cloudflared --no-pager
sudo journalctl -u cloudflared -n 100 --no-pager
```

Manage your manual connector and its token using Cloudflare's instructions. If you opt into the Compose connector instead, check `docker compose logs --tail=100 cloudflared`; rotate its token in `hermes_cloudflare_tunnel_token` and reapply `site.yml`.

To change the dashboard password, generate a new hash with `bash scripts/hash-dashboard-password.sh`, replace `hermes_dashboard_password_hash` using `ansible-vault edit`, and reapply. For dashboard login-session invalidation, rotate `hermes_dashboard_session_secret` too; the signing-secret change invalidates existing sessions. The Vault passphrase is separate from the dashboard password.

## Inspect authentication events

On the Hermes VM:

```bash
sudo tail -n 30 /srv/hermes/logs/dashboard-auth.log
```

See [Login throttling and bot protection](login-protection.md) for event names, visitor-IP checks, and the separate Cloudflare rate-limit rule. If a login is throttled, wait for the applicable window to expire; a dashboard restart resets Hermes's in-memory counters but not Cloudflare's edge block.

## Select a hosted model

See [Hosted model providers](model-providers.md) for ChatGPT/Codex login and OpenCode Zen. Keep Ansible provider overrides empty when using Hermes's provider picker. On the VM:

```bash
cd /opt/hermes-agent
docker compose exec --user hermes dashboard hermes model
docker compose restart gateway dashboard
```
