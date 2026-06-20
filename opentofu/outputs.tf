output "vm_name" {
  value = proxmox_virtual_environment_vm.hermes.name
}

output "ansible_inventory" {
  value = local_file.ansible_inventory.filename
}

output "hermes_ssh" {
  value = "ssh ubuntu@${local.ansible_host}"
}
