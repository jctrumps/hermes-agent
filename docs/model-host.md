# Model Host

Use this guide only if you choose Ollama on a separate model host. For ChatGPT/Codex subscription login or OpenCode Zen, use [Hosted model providers](model-providers.md); no local model host is needed.

Example endpoint (enable it explicitly in local Ansible settings):

```text
http://10.10.10.20:11434/v1
```

## Expectations

- Ollama runs on a dedicated model host.
- Ollama is not installed on the Hermes VM by this project.
- Ollama stays LAN-only.
- Firewall rules should limit port `11434` to trusted clients where practical.

## Check from the Hermes VM

```bash
curl -fsS http://10.10.10.20:11434/v1/models | jq .
```

Or use the helper from a machine that can reach the model host:

```bash
scripts/check-ollama.sh
```

Override the endpoint when testing a different host:

```bash
OLLAMA_BASE_URL=http://<OLLAMA_HOST>:11434/v1 scripts/check-ollama.sh
```

## Change the default endpoint

Edit:

```text
ansible/group_vars/hermes.yml
```

Set:

```yaml
hermes_openai_base_url: "http://<OLLAMA_HOST>:11434/v1"
hermes_default_model: "openai/<OLLAMA_MODEL_NAME>"
```

In local `ansible/group_vars/hermes_vault.yml`, uncomment/set:

```yaml
hermes_openai_api_key: "ollama-local"
```

Redeploy the app layer:

```bash
cd ansible
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini site.yml
```

## Firewall example on the Ollama host

Replace `<HERMES_VM_IP>` with the Hermes VM address:

```bash
sudo ufw allow from <HERMES_VM_IP> to any port 11434 proto tcp
```
