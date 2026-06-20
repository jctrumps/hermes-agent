# Runbook

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
curl -fsS http://192.168.86.16:11434/v1/models | jq .
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
