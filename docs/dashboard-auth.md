# Dashboard password hashes and Ansible Vault

This project deploys a scrypt password hash, not the actual dashboard password. Hermes verifies the password you enter against that hash. Your username remains `hermes_dashboard_username` in local `ansible/group_vars/hermes.yml`.

## What are the three credentials?

| Credential | Purpose | Where it belongs |
|---|---|---|
| Dashboard password | You type it to log in to Hermes | Remember it or keep a secure offline record; do not put it in Ansible |
| Session-signing secret | Hermes signs dashboard login sessions | Encrypted local `hermes_vault.yml`; Ansible deploys it to the VM |
| Ansible Vault password | You unlock the encrypted local secrets file when editing/deploying | Remember it or keep a secure offline record; do not store it in the repository |

Use a different passphrase for the Vault password and dashboard password. A password manager is not required to complete this setup. A long passphrase made from several randomly selected words is easier to type; at least 16 characters is recommended for the dashboard. The hash helper allows shorter passwords for testing and prints a warning. Avoid names, dates, quotations, or predictable phrases. A secure paper record is an option until you adopt a password manager. Neither the dashboard hash nor an encrypted file lets you recover a forgotten password without the relevant credential.

Ansible Vault is built into Ansible. It encrypts the file at rest on your workstation. You enter the Vault password when Ansible needs to decrypt it; the Vault password is not deployed to Hermes. It does not encrypt the running app's environment on the VM: Hermes needs the hash and signing secret at runtime, and the rendered file is restricted to mode `0600`.

## 1. Generate the dashboard password hash

From the repository root in WSL/Linux:

```bash
bash scripts/hash-dashboard-password.sh
```

Enter your chosen dashboard password twice. Input is hidden and the password does not appear in command history. The helper uses Python's standard library, a random salt, and Hermes's scrypt parameters; it does not need a running container or an online hashing service. It prints only the resulting hash:

```text
scrypt$16384$8$1$<salt>$<derived-key>
```

The displayed example is a format description, not a usable hash. Copy the complete actual output. Running the helper again produces a different salt/hash even for the same password; that is expected.

## 2. Update the local secrets file

Edit `ansible/group_vars/hermes_vault.yml`, preserving any unrelated secrets:

```yaml
hermes_dashboard_password_hash: '<COMPLETE_SCRYPT_HASH>'
hermes_dashboard_session_secret: '<RANDOM_SESSION_SIGNING_SECRET>'
```

Remove the old `hermes_dashboard_password` setting, if present. Do not paste a hash into that old setting. Use single quotes around the hash and keep it on one line; dollar signs are part of the format. Ansible handles escaping them for Compose.

If setting the session secret for the first time, generate it in WSL/Linux:

```bash
openssl rand -hex 32
```

Paste that output into the session-secret setting. Keep an existing secret for a hash-only migration if you want to preserve existing sessions. Rotate it whenever you want to invalidate all dashboard login sessions.

## 3. Encrypt the local file

From the repository's `ansible/` directory:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-vault encrypt group_vars/hermes_vault.yml
```

Choose and confirm a separate Vault passphrase. The command encrypts the existing file in place; the result starts with `$ANSIBLE_VAULT`. Keep the encrypted file out of Git, just like the plaintext local file. The file name alone did not encrypt it before this command.

If the file is already encrypted, use `ansible-vault edit` below instead of encrypting it again. If you forget the Vault password, its encrypted contents cannot be recovered through Ansible; keep a secure record or backup strategy for that password.

## 4. Deploy with a Vault prompt

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --ask-vault-pass --syntax-check site.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --ask-vault-pass site.yml
```

Enter your **Vault passphrase**, not the dashboard password, at the prompt. Ansible decrypts the local file, deploys only the hash and signing secret to `dashboard.env`, and updates the dashboard container. The plaintext dashboard-password environment variable is no longer supplied.

The existing status, logs, and restart playbooks also load the Vault file, so add the same flag:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --ask-vault-pass playbooks/status.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --ask-vault-pass playbooks/logs.yml
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory/hosts.ini --ask-vault-pass playbooks/restart.yml
```

Use these explicit commands instead of the current Makefile app/operations helpers after encrypting the file; those helpers do not prompt for a Vault password. Add `--ask-vault-pass` to other playbook examples in this repository whenever they load your encrypted local file.

## 5. Change your password later

1. Run the hash helper again with your new dashboard password.
2. From `ansible/`, edit the encrypted file:

   ```bash
   ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-vault edit group_vars/hermes_vault.yml
   ```

3. Replace `hermes_dashboard_password_hash`. Replace the session secret too if you want existing login sessions signed out.
4. Save and close the editor. Ansible Vault re-encrypts the file automatically.
5. Reapply `site.yml` using `--ask-vault-pass` as above.

Do not decrypt the whole file to disk just to edit it. You can change the Vault passphrase separately with:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-vault rekey group_vars/hermes_vault.yml
```

Changing the Vault passphrase does not change the dashboard password or invalidate dashboard sessions.

## Cloudflare Access is optional

Cloudflare Tunnel provides the route and browser HTTPS; Hermes supplies the username/password login. You can use that app login without an Access application. Adding Cloudflare Access later provides a separate outer identity gate but is not required by this project. See [Cloudflare Tunnel hosting](cloudflare-tunnel.md) for routing and verification.
