# Backup And Restore

Back up Hermes data and the local deployment inputs. Do not back up generated provider caches.

## What to back up

| Location | Why |
|---|---|
| `/srv/hermes` on the Hermes VM | Persistent Hermes data |
| `opentofu/terraform.tfvars` on the operator workstation | Local Proxmox and VM settings |
| `ansible/group_vars/hermes_vault.yml` on the operator workstation | Local secrets and API placeholders |
| `ansible/group_vars/hermes.yml` in source control | Non-secret runtime defaults |

## VM data backup

From the Hermes VM:

```bash
sudo tar -czf /tmp/hermes-data-$(date +%Y%m%d).tgz -C /srv hermes
```

Copy the archive to trusted storage:

```bash
scp ubuntu@hermes-01:/tmp/hermes-data-YYYYMMDD.tgz ./
```

## Restore VM data

Stop the stack first:

```bash
ssh ubuntu@hermes-01
cd /opt/hermes-agent
docker compose down
```

Restore the archive:

```bash
sudo tar -xzf /tmp/hermes-data-YYYYMMDD.tgz -C /srv
sudo chown -R ubuntu:ubuntu /srv/hermes
```

Start the stack again:

```bash
cd /opt/hermes-agent
docker compose up -d
```

## Rebuild from infrastructure code

Use this path if the VM is disposable and the data has already been backed up:

```bash
make infra-apply
make app
```

Then restore `/srv/hermes` if needed.

## Do not include

- `opentofu/.terraform/`
- `opentofu/*.tfstate*` unless you intentionally manage state backups securely
- rendered `/opt/hermes-agent/.env` outside trusted secret storage
- private SSH keys in ad hoc archives
