# Model Host

Hermes Agent uses an OpenAI-compatible API endpoint and points at Ollama on the model host.

Default endpoint:

```text
http://192.168.86.16:11434/v1
```

## Expectations

- Ollama runs on Blade 6 or another dedicated model host.
- Ollama is not installed on the Hermes VM by this project.
- Ollama stays LAN-only.
- Firewall rules should limit port `11434` to trusted clients where practical.

## Check from the Hermes VM

```bash
curl -fsS http://192.168.86.16:11434/v1/models | jq .
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
```

Redeploy the app layer:

```bash
make app
```

## Firewall example on the Ollama host

Replace `<HERMES_VM_IP>` with the Hermes VM address:

```bash
sudo ufw allow from <HERMES_VM_IP> to any port 11434 proto tcp
```
