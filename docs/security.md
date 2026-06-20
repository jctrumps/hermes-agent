# Security notes

Hermes Agent can run tools, access files, and keep memory, so treat it as more sensitive than a normal chat frontend.

## Defaults in this project

- Dashboard binds to `127.0.0.1`.
- Dashboard should be accessed with SSH tunneling.
- `.env` and vault files are ignored by Git.
- UFW denies inbound traffic by default except SSH.
- Ollama should not be exposed to the internet.
- `ansible/inventory/hosts.ini` is generated and local-only.
- `opentofu/terraform.tfvars` and Ansible vault files stay out of Git.

## Ollama access

On Blade 6, prefer firewalling port `11434` so only trusted hosts can reach it:

```bash
sudo ufw allow from 192.168.86.52 to any port 11434 proto tcp
```

Replace `192.168.86.52` with your Hermes VM IP.

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
