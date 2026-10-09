# Hosted model providers

Hermes can use ChatGPT/Codex subscription login and OpenCode Zen without a local LLM. These provider credentials are separate from your Hermes dashboard password and Cloudflare login.

## 1. Leave Ansible provider overrides unset

Edit local `ansible/group_vars/hermes.yml`:

```yaml
hermes_openai_base_url: ""
hermes_default_model: ""
```

In local `ansible/group_vars/hermes_vault.yml`, comment out or remove `hermes_openai_api_key`. Do not keep `ollama-local` for hosted provider login. Keep your dashboard password hash and session secret. For an encrypted file, edit it with `ansible-vault edit` and add `--ask-vault-pass` to the playbook commands below; see [Dashboard hashes and Ansible Vault](dashboard-auth.md).

Empty/omitted overrides cause Ansible to omit `OPENAI_BASE_URL`, `OPENAI_API_KEY`, and `HERMES_MODEL` from its generated environment. Hermes's provider picker can then manage provider credentials and models without an Ansible Ollama override. Reapply Ansible after changing those values:

```bash
cd ansible
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --syntax-check site.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini site.yml
```

On an existing deployment, rebuild the image for current provider support if you have not already done so:

```bash
cd /opt/hermes-agent
docker compose build gateway
docker compose up -d
```

## 2. Sign in with ChatGPT Plus

Use the **ChatGPT or Codex Subscription / OpenAI Codex** provider, not the direct OpenAI API-key provider. A ChatGPT Plus subscription does not supply an OpenAI API key or API billing credits; Hermes's supported Codex login uses your subscription's available models and limits.

On the Hermes VM:

```bash
cd /opt/hermes-agent
docker compose exec --user hermes dashboard hermes auth add openai-codex
```

Follow the displayed link in your workstation browser, enter the displayed device code, and sign in with your ChatGPT account. This default device-code flow completes in your browser without needing a callback port forwarded from the VM.

Then choose the active provider/model:

```bash
docker compose exec --user hermes dashboard hermes model
```

Select **OpenAI**, then **ChatGPT or Codex Subscription** (provider ID `openai-codex`), and choose one of the offered models. Menu wording can vary by upstream version. Reuse the login you just added.

Check credentials and restart the running services to load the selection:

```bash
docker compose exec --user hermes dashboard hermes auth status openai-codex
docker compose restart gateway dashboard
```

The services share the persistent `/srv/hermes` data directory, where Hermes stores its provider configuration and login credentials. You do not paste the OAuth tokens into Ansible settings. Running these commands as the container's `hermes` user preserves the correct file ownership.

### If you specifically want the browser callback flow

Current Hermes also supports `--browser`. From your workstation, keep this SSH tunnel open:

```bash
ssh -L 1455:127.0.0.1:1455 ubuntu@<HERMES_VM_IP>
```

In a second terminal on the Hermes VM, run:

```bash
cd /opt/hermes-agent
docker compose exec --user hermes dashboard hermes auth add openai-codex --browser --no-browser
```

Open the displayed authorization URL in the workstation browser. The localhost callback reaches the VM through SSH; your Cloudflare dashboard hostname is not this OAuth callback. Then select the provider/model as above.

## 3. Optional: add OpenCode Zen

Current upstream Hermes includes an **OpenCode Zen** provider (`opencode-zen`). Get a Zen API key by signing in at [OpenCode Zen](https://opencode.ai/auth). A ChatGPT subscription login does not authenticate to Zen; it needs its own key.

On the VM, add the key interactively so it does not appear in a shell command:

```bash
cd /opt/hermes-agent
docker compose exec --user hermes dashboard hermes auth add opencode-zen --type api-key
docker compose exec --user hermes dashboard hermes model
```

Select **OpenCode**, then **OpenCode Zen**, and choose a model listed as free in the [current Zen pricing documentation](https://opencode.ai/docs/zen/). For example, that documentation currently lists `big-pickle` as free; free offerings and availability can change. The provider handles Zen's endpoint and model-specific API format, so leave the Ansible OpenAI overrides empty.

After choosing a model:

```bash
docker compose restart gateway dashboard
```

Zen has both free and paid models; choose the explicitly free model rather than assuming every Zen model is free. Review the current model listing/pricing when switching. You can keep both Codex and Zen credentials stored in Hermes and use `hermes model` to change the active provider/model; adding both credentials does not automatically set up failover.

## Troubleshooting

- **Still tries an Ollama endpoint/model:** clear the Ansible provider overrides and reapply. If you previously configured the same overrides manually in Hermes's persistent `.env` or configuration, clear those too and select the hosted provider again.
- **Unknown provider or unsupported command:** rebuild the image from the updated upstream source. These instructions use current upstream `hermes auth` and `hermes model` commands.
- **Codex login unavailable or rate-limited:** check `hermes auth status openai-codex` and the account/subscription's available Codex access and limits.
- **Zen model missing or no longer free:** use the current live picker and Zen pricing documentation instead of an old model name.
