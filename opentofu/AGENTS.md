# AGENTS.md

## Scope

This directory owns Proxmox VM provisioning for the Hermes Agent host.

## Rules

- Do not read, print, or copy values from `terraform.tfvars` unless the user explicitly asks.
- Keep `terraform.tfvars.example` realistic but free of real hostnames, tokens, and keys.
- Keep generated state, plans, and provider caches out of source control.
- Preserve the Ubuntu 24.04 cloud-init template flow unless the user changes the target OS.
- Keep this layer focused on VM lifecycle only; do not configure Docker or Hermes here.
- If Windows Application Control blocks provider `.exe` files, document WSL/Linux as the preferred operator path instead of weakening security policy in code.

## Expected outputs

- The VM resource should remain in `main.tf` unless the project intentionally grows beyond one host.
- The generated Ansible inventory should point at the VM and use the cloud-init `ubuntu` user.
- New variables should include clear descriptions and safe defaults when possible.

## Validation

Run from this directory when tools and credentials are available:

```bash
tofu fmt -check
tofu validate
tofu plan
```

From WSL on the Windows checkout, run from `/mnt/c/projects/hermes-agent/opentofu` and reinitialize so Linux provider binaries are downloaded.
