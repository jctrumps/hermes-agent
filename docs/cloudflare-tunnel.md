# Cloudflare Tunnel hosting

Run the tunnel connector on the Hermes VM and publish the dashboard at an HTTPS hostname. This guide uses `hermes.example.com`; replace it with your domain in local settings and Cloudflare.

```text
Browser -> Cloudflare HTTPS -> Cloudflare Tunnel
        -> cloudflared on the Hermes VM -> http://127.0.0.1:9119
        -> Hermes username/password login
```

OpenTofu provisions the VM, Ansible renders Hermes settings, and Compose runs Hermes. Install/manage `cloudflared` separately on the Hermes VM using Cloudflare's instructions. This guide uses that manually managed connector by default.

## Which files do I edit?

Edit `ansible/group_vars/hermes.yml` and `ansible/group_vars/hermes_vault.yml`. The `.example` files are reference templates, not the active deployment settings. Copy them only if the corresponding local file does not already exist; preserve any existing local settings.

The dashboard public URL is the complete address, such as `https://hermes.example.com`, including `https://`. It is not just a hostname or the VM's LAN address. Keep `hermes_dashboard_host` at `127.0.0.1`: that is where the app listens on the VM, not the address you enter in your browser.

## 1. Create the Cloudflare Tunnel

In Cloudflare Zero Trust:

1. Create a **Cloudflare Tunnel** and run Cloudflare's Linux connector installation command on the Hermes VM. Manage this connector separately; no tunnel token is needed in Ansible for this setup.
2. Add a published application route/public hostname with these settings:

| Cloudflare setting | Value |
|---|---|
| Subdomain | `hermes` |
| Domain | `example.com` (your domain) |
| Path | Empty; route all paths |
| Service type | **HTTP** |
| Service URL | `127.0.0.1:9119` |
| Full origin URL | `http://127.0.0.1:9119` |
| HTTP Host Header override | Leave empty; preserve the public hostname |
| Origin TLS / No TLS Verify | Not needed for this HTTP loopback origin |

Cloudflare terminates browser HTTPS. The connector reaches the HTTP origin over loopback, so no origin certificate, inbound port forwarding, or UFW rule for `9119`, `80`, or `443` is needed. Allow the connector's outbound Cloudflare connectivity (port `7844`, UDP for QUIC or TCP for HTTP/2).

Let Cloudflare create the tunnel DNS record, or create a proxied CNAME from your hostname to `<TUNNEL_ID>.cfargotunnel.com`.

The manually installed connector runs directly on the Linux VM, so `127.0.0.1` reaches Hermes. If you install it in a separate Docker container instead, it needs host networking to use this same origin address.

### Optional: add Cloudflare Access later

An Access application is not required: Hermes's username/password login protects the dashboard. If you later want a separate outer login gate, create a **Self-hosted Access application** for the entire hostname (all paths) with an **Allow** policy limited to your email or trusted identity-provider group. Access and Tunnel are separate features.

## 2. Set the application variables

Edit the ignored `ansible/group_vars/hermes.yml`:

```yaml
hermes_dashboard_host: "127.0.0.1"
hermes_dashboard_port: 9119
hermes_allow_dashboard_from_lan: false
hermes_dashboard_public_url: "https://hermes.example.com"
hermes_dashboard_username: "hermes-admin"
hermes_cloudflare_tunnel_enabled: false

hermes_enable_ufw: true
hermes_lan_cidr: "10.10.10.0/24"

# Select hosted providers inside Hermes instead of overriding them here.
hermes_openai_base_url: ""
hermes_default_model: ""
```

Keep the public URL at the hostname root with no trailing slash. Ansible supplies `HERMES_DASHBOARD_PUBLIC_URL` to the dashboard; Hermes uses this for public links and Host/WebSocket Origin validation. Loopback proxy connections are trusted by Hermes by default.

`hermes_cloudflare_tunnel_enabled: false` means **the project does not manage the connector**. It does not disable access through your separately installed Cloudflare Tunnel.

### What is UFW?

UFW means **Uncomplicated Firewall**, Ubuntu's firewall management tool:

- `hermes_enable_ufw: true`: enable the VM firewall. The playbook permits inbound SSH and denies other unsolicited inbound traffic.
- `hermes_allow_dashboard_from_lan: false`: do not add a LAN firewall exception for port `9119`. Keep this false for your same-VM tunnel.
- `hermes_lan_cidr`: the allowed LAN subnet if that exception is enabled. It is not the VM's IP. With LAN dashboard access false, this value is unused, so leave the example value alone.

Your VM's actual LAN IP belongs in the generated/local Ansible inventory, not `hermes_dashboard_host` or the tunnel origin URL. Do not change the application paths, source repository, or dashboard port for domain hosting.

Edit the ignored `ansible/group_vars/hermes_vault.yml`, preserving the existing provider settings:

```yaml
hermes_dashboard_password_hash: '<COMPLETE_SCRYPT_HASH>'
hermes_dashboard_session_secret: "<RANDOM_SESSION_SIGNING_SECRET>"
```

Generate the hash by running `bash scripts/hash-dashboard-password.sh` from the repository root in WSL/Linux. It prompts twice without echoing the password and prints a Hermes-compatible scrypt hash. Remove the old `hermes_dashboard_password` setting; only the hash is deployed. Generate a session-signing secret with:

```bash
openssl rand -hex 32
```

The password is what you type at the Hermes login page. The session secret is an internal signing key; you never type it to log in. Generate it once and keep it stable across redeployments. Rotating it invalidates existing login sessions.

Hermes's bundled password provider verifies your login against the supplied hash. Ansible writes the hash and signing secret to `/opt/hermes-agent/dashboard.env`, mode `0600`, with task output/diffs suppressed. Only the dashboard service loads this file. Follow [Dashboard hashes and Ansible Vault](dashboard-auth.md) to encrypt the local `hermes_vault.yml`; a Vault passphrase unlocks that file for editing/deploying and is not deployed to Hermes.

You can leave `hermes_api_server_key` commented out: this stack starts the gateway and dashboard, not the separate API server. This key is for authenticating external clients to that separately enabled API server; it is neither a model-provider key nor a dashboard password.

For ChatGPT/Codex browser login, leave `hermes_openai_api_key` commented out and both provider overrides empty as shown above. Do not leave the old Ollama URL/model active. See [Hosted model providers](model-providers.md) for ChatGPT subscription login and optional OpenCode Zen models.

Current upstream Hermes requires an app auth provider when a non-loopback public URL is declared, even with a loopback bind. Hermes provides its own username/password login; Cloudflare Access is optional. The deprecated `--insecure` flag is not used.

## 3. Deploy

From the repository's `ansible/` directory in WSL/Linux, after encrypting the local secrets file:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --ask-vault-pass --syntax-check site.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --ask-vault-pass site.yml
```

Enter the Vault passphrase at the prompt. If you have not encrypted the local file yet, omit `--ask-vault-pass`.

For an existing deployment, rebuild the Hermes image to include current upstream dashboard authentication. Ansible updates the source checkout, but its `build: policy` setting reuses an existing image. On the Hermes VM after applying Ansible:

```bash
cd /opt/hermes-agent
docker compose build gateway
docker compose up -d
```

## 4. Verify

On the Hermes VM:

```bash
cd /opt/hermes-agent
docker compose ps
docker compose logs --tail=100 dashboard
sudo systemctl status cloudflared --no-pager
sudo journalctl -u cloudflared -n 100 --no-pager
curl -I http://127.0.0.1:9119/login
sudo ss -lntp 'sport = :9119'
```

The connector should report registered tunnel connections, the dashboard should serve its login page, and port `9119` should listen only on `127.0.0.1`.

Open `https://hermes.example.com` in a private browser window. Confirm Hermes requires a username/password login, then log in with your actual password, not the hash. Verify dashboard pages and a chat session work, including the WebSocket connection. If you enabled Cloudflare Access, verify its identity gate and denial of identities outside your policy too.

Keep Cloudflare WebSockets enabled and add a cache rule to **bypass cache for the whole Hermes hostname**, especially `/api/*`, `/auth/*`, and `/login`. Avoid a Cache Everything rule on this application.

After confirming login works, follow [Login throttling and bot protection](login-protection.md) to add a Cloudflare rate-limiting rule for `/auth/password-login`. The guide covers Hermes's built-in 10-attempt/60-second throttle, the Free-plan 5-request/10-second burst rule, optional bot detection, and checking visitor IPs in the auth audit log. Cloudflare Access is not required for the rate-limiting rule.

## Troubleshooting

- **Cloudflare 502:** check the dashboard container and the route's HTTP origin `127.0.0.1:9119`. The manually installed connector must run on the Hermes VM.
- **Tunnel disconnected / 1033:** check `systemctl status cloudflared`, the connector's journal, and outbound port `7844` connectivity.
- **Dashboard refuses to start / no auth providers:** rebuild the Hermes image, check the dashboard credentials, and ensure the upstream `basic` dashboard-auth plugin is enabled if you previously disabled it.
- **Invalid Host or WebSocket Origin:** confirm the public URL exactly matches the browser hostname and leave the tunnel's HTTP Host Header override empty.
- **Login loops or chat disconnects:** check WebSockets are enabled, cache is bypassed, and the connector forwards HTTPS scheme information. If using Access, check that it covers all paths. Loopback is already a trusted proxy; do not use wildcard trusted proxies.

## Disable public access / rollback

First remove or disable the Cloudflare published application route. In local `hermes.yml`, set:

```yaml
hermes_cloudflare_tunnel_enabled: false
hermes_dashboard_public_url: ""
hermes_dashboard_host: "127.0.0.1"
hermes_allow_dashboard_from_lan: false
```

Reapply `site.yml` using the deploy command above. Ansible removes the unused dashboard environment file after the stack is updated. Your manually installed connector remains separately managed; stop it with `sudo systemctl stop cloudflared` if you want it stopped. Clear any separately configured `dashboard.public_url` or basic-auth settings from Hermes's persistent configuration if you added them manually.

Use the existing SSH tunnel for local browser access:

```bash
ssh -L 9119:127.0.0.1:9119 ubuntu@hermes-01
```

Then open `http://127.0.0.1:9119`.

## Optional: let Compose manage the connector instead

Use this only if you want the project to run `cloudflared`. Set these in local `hermes.yml`:

```yaml
hermes_cloudflare_tunnel_enabled: true
hermes_cloudflared_image: "cloudflare/cloudflared:latest"
```

Add the connector token to local `hermes_vault.yml`:

```yaml
hermes_cloudflare_tunnel_token: "<CLOUDFLARE_TUNNEL_CONNECTOR_TOKEN>"
```

Ansible renders `/opt/hermes-agent/cloudflared.env`, mode `0600`, loaded only by the Compose connector. Compose uses host networking to reach the same loopback origin. Stop the manually installed connector before using this mode. Check the Compose connector with `docker compose logs --tail=100 cloudflared`; switching this flag back to false and reapplying removes the Compose connector and its environment file.
