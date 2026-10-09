# Security notes

Hermes Agent can run tools, access files, and keep memory, so treat it as more sensitive than a normal chat frontend.

## Defaults in this project

- Dashboard binds to `127.0.0.1`.
- Dashboard should be accessed with SSH tunneling.
- Optional domain access uses a same-VM Cloudflare Tunnel and Hermes dashboard username/password authentication; Cloudflare Access is optional. See [Cloudflare Tunnel hosting](cloudflare-tunnel.md).
- `.env` and vault files are ignored by Git.
- UFW denies inbound traffic by default except SSH.
- Ollama should not be exposed to the internet.
- `ansible/inventory/hosts.ini` is generated and local-only.
- `opentofu/terraform.tfvars`, `ansible/group_vars/hermes.yml`, and Ansible vault files stay out of Git.
- Public docs and examples use `10.10.10.0/24` only.

## Cloudflare hosting

Keep the dashboard bound to localhost and LAN dashboard access disabled. A manually installed connector runs directly on the VM and reaches the loopback origin with outbound connections to Cloudflare. The optional Compose connector uses host networking for the same purpose. Public URL configuration also activates Hermes's app authentication and declares the hostname trusted by Host/WebSocket Origin validation.

Keep only the dashboard password hash and session-signing secret in the ignored local Ansible vault file; encrypt it using the steps in [Dashboard hashes and Ansible Vault](dashboard-auth.md). The actual dashboard password is not deployed. A tunnel token belongs in that file only when choosing the optional Compose connector. Rendered `dashboard.env` and optional `cloudflared.env` files are mode `0600` and loaded only by their respective services. Bypass Cloudflare caching for the application. If adding Access later, use an Allow policy limited to trusted identities for the entire hostname.

## Login throttling and bots

Current upstream Hermes limits password-login attempts to 10 per client IP per rolling 60 seconds and returns HTTP `429` when over limit. All attempts count; its process-local counters reset on restart. It is not a permanent account lockout or CAPTCHA system.

[Login throttling and bot protection](login-protection.md) documents a Cloudflare login-endpoint rule (5 requests per IP in 10 seconds, block for 10 seconds), plan-specific matching, optional Bot Fight Mode, and client-IP/audit verification. These edge settings are configured separately in Cloudflare. Cloudflare Access remains optional.

## Ollama access

On the model host, prefer firewalling port `11434` so only trusted hosts can reach it:

```bash
sudo ufw allow from 10.10.10.50 to any port 11434 proto tcp
```

Replace `10.10.10.50` with your Hermes VM IP.

## Do not expose these publicly without auth

- Hermes dashboard
- Hermes API server
- Ollama API

## Safe change process

If you need LAN or internet access to the dashboard, add these first:

- authentication
- TLS termination or a trusted reverse proxy
- explicit firewall rules limited to trusted clients
- updated runbook and rollback notes

## Public repository checks

Before publishing, review `docs/public-repo-checklist.md` and confirm no local-only config files are tracked.
