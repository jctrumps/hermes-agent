# SSH Guide

This project uses SSH in three places:

- Windows PowerShell to the Proxmox host
- Windows PowerShell to a temporary Ubuntu VM
- Proxmox cloud-init SSH key injection for the final template

## Create A Dedicated Key

From Windows PowerShell:

```powershell
ssh-keygen -t ed25519 -f "$HOME\.ssh\proxmox_templates_ed25519" -C "proxmox-templates"
```

Files created:

- `C:\Users\<YOUR_NAME>\.ssh\proxmox_templates_ed25519`
- `C:\Users\<YOUR_NAME>\.ssh\proxmox_templates_ed25519.pub`

## Remove An Old Host Key

If the host was rebuilt and SSH warns about a changed key:

```powershell
ssh-keygen -R <IP_ADDRESS>
```

## Copy The Public Key To Proxmox

From Windows PowerShell:

```powershell
scp "$HOME\.ssh\proxmox_templates_ed25519.pub" root@<PROXMOX_IP>:/root/
```

## SSH To The Proxmox Host

If the dedicated key is already trusted on the Proxmox host:

```powershell
ssh -i "$HOME\.ssh\proxmox_templates_ed25519" root@<PROXMOX_IP>
```

If not, use your current working login method once, then install the public key into `/root/.ssh/authorized_keys`.

## Add The Public Key To A VM In The Proxmox UI

For VM `9024`:

1. Open the VM.
2. Go to `Cloud-Init`.
3. Edit `SSH public keys`.
4. Paste the contents of `C:\Users\<YOUR_NAME>\.ssh\proxmox_templates_ed25519.pub`.
5. Apply the change.
6. Reboot the VM.

Paste the `.pub` file content only. Do not paste the private key.

## Add The Public Key From The Proxmox Shell

If you prefer the shell:

```bash
qm set 9024 --sshkey /root/proxmox_templates_ed25519.pub
qm reboot 9024
```

## SSH To The Ubuntu VM

Once the VM has an IP address:

```powershell
ssh -i "$HOME\.ssh\proxmox_templates_ed25519" ubuntu@<VM_IP>
```

Default cloud-init user for this template:

- `ubuntu`

## Find The VM IP

Before `qemu-guest-agent` is installed, use one of these:

- check DHCP leases on your router or DHCP server
- match the VM MAC address in Proxmox against `ip neigh` on the Proxmox host

Example on the Proxmox host:

```bash
ip neigh
ip neigh | grep -i "<VM_MAC_ADDRESS>"
```

## Optional SSH Config On Windows

Create `C:\Users\<YOUR_NAME>\.ssh\config`:

```sshconfig
Host proxmox
    HostName <PROXMOX_IP>
    User root
    IdentityFile C:/Users/<YOUR_NAME>/.ssh/proxmox_templates_ed25519
    IdentitiesOnly yes

Host ubuntu-template
    HostName <VM_IP>
    User ubuntu
    IdentityFile C:/Users/<YOUR_NAME>/.ssh/proxmox_templates_ed25519
    IdentitiesOnly yes
```

Then connect with:

```powershell
ssh proxmox
ssh ubuntu-template
```

## Template Notes

- keep the private key on your Windows machine only
- inject only the public key into Proxmox or the VM
- before converting the VM to a template, remove guest SSH host keys so clones generate unique host keys on first boot
- Proxmox assigns a fresh virtual NIC MAC address to cloned VMs
