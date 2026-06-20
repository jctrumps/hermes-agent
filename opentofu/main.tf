resource "proxmox_virtual_environment_vm" "hermes" {
  name      = var.vm_name
  node_name = var.node_name
  vm_id     = var.vm_id

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory_mb
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size_gb
  }

  initialization {
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }

    ip_config {
      ipv4 {
        address = var.ipv4_address == null ? "dhcp" : var.ipv4_address
        gateway = var.ipv4_gateway
      }
    }
  }
}

locals {
  ansible_host = var.ipv4_address == null ? var.vm_name : split("/", var.ipv4_address)[0]
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory/hosts.ini"

  content = <<-EOT
[hermes]
${var.vm_name} ansible_host=${local.ansible_host} ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3 ansible_ssh_private_key_file=${var.ssh_private_key_file} ansible_ssh_common_args='-o IdentitiesOnly=yes'
EOT
}
