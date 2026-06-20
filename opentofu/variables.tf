variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, for example https://pve.example.local:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in user@realm!token=value format. Prefer environment or tfvars kept out of Git."
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Allow insecure TLS for lab Proxmox certificates."
  type        = bool
  default     = true
}

variable "node_name" {
  description = "Proxmox node name."
  type        = string
}

variable "vm_id" {
  description = "Target VM ID for hermes-01."
  type        = number
  default     = 9102
}

variable "vm_name" {
  description = "VM and hostname."
  type        = string
  default     = "hermes-01"
}

variable "template_vm_id" {
  description = "Existing Ubuntu 24.04 cloud-init template VM ID."
  type        = number
  default     = 9024
}

variable "cpu_cores" {
  description = "Hermes does not run the model locally. 2 cores is enough to start."
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "Hermes controller/UI memory. 4096 is minimum, 8192 preferred."
  type        = number
  default     = 4096
}

variable "disk_size_gb" {
  type    = number
  default = 40
}

variable "datastore_id" {
  type    = string
  default = "local-lvm"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "ipv4_address" {
  description = "CIDR address, for example 192.168.86.52/24. Leave null if using DHCP."
  type        = string
  default     = null
}

variable "ipv4_gateway" {
  description = "Gateway address, for example 192.168.86.1. Leave null if using DHCP."
  type        = string
  default     = null
}

variable "ssh_public_key" {
  description = "Public SSH key for cloud-init user."
  type        = string
}

variable "ssh_private_key_file" {
  description = "Private key path used by generated Ansible inventory."
  type        = string
  default     = "~/.ssh/hermes_01_ed25519"
}

variable "cpu_type" {
  description = "Proxmox CPU type/model. Use 'host' to expose host CPU features to the VM."
  type        = string
  default     = "host"
}
