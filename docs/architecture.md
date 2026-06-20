# Architecture

Hermes Agent runs on a small VM or mini box. Model inference stays on a separate Ollama host.

```text
operator laptop
  -> SSH / OpenTofu / Ansible
  -> Proxmox VE
  -> hermes-01
      -> Docker Compose
      -> Hermes gateway
      -> Hermes dashboard on 127.0.0.1:9119
      -> Ollama API on Blade 6
```

## Layers

| Layer | Path | Responsibility |
|---|---|---|
| OpenTofu | `opentofu/` | Create the Proxmox VM from an Ubuntu 24.04 cloud-init template |
| Ansible | `ansible/` | Configure packages, Docker, directories, firewall, and Compose files |
| Compose | rendered to `/opt/hermes-agent/compose.yml` | Build and run Hermes Agent containers |
| Docs | `docs/` | Deployment, operations, and security notes |

## Runtime paths

| Path | Purpose |
|---|---|
| `/opt/hermes-agent` | Rendered Compose project and `.env` file |
| `/opt/hermes-agent/src` | Upstream Hermes Agent source clone |
| `/srv/hermes` | Persistent Hermes data mounted into containers |

## Network defaults

| Service | Default | Exposure |
|---|---|---|
| SSH | TCP `22` | Allowed by UFW |
| Hermes dashboard | TCP `9119` bound to `127.0.0.1` | SSH tunnel only |
| Ollama API | TCP `11434` on Blade 6 | LAN-only, ideally limited to trusted clients |

## Data flow

1. User accesses the dashboard through an SSH tunnel.
2. Dashboard and gateway run on the Hermes VM.
3. Hermes sends OpenAI-compatible API requests to Ollama.
4. Ollama performs inference on the model host.
5. Hermes state remains under `/srv/hermes` on the Hermes VM.

## Security boundary

The Hermes VM is an application host, not a model host. It should not expose the dashboard or API directly to the LAN or internet unless authentication and a reverse proxy are added intentionally.
