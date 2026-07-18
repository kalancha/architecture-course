output "network_id" {
  description = "Идентификатор созданной VPC-сети."
  value       = yandex_vpc_network.main.id
}

output "subnet_id" {
  description = "Идентификатор прикладной подсети."
  value       = yandex_vpc_subnet.main.id
}

output "security_group_id" {
  description = "Идентификатор группы безопасности ВМ."
  value       = yandex_vpc_security_group.vm.id
}

output "vm_id" {
  description = "Идентификатор виртуальной машины."
  value       = yandex_compute_instance.app.id
}

output "vm_private_ip" {
  description = "Приватный IP виртуальной машины."
  value       = yandex_compute_instance.app.network_interface[0].ip_address
}

output "vm_public_ip" {
  description = "Динамический публичный IP; пустой при enable_nat = false."
  value       = try(yandex_compute_instance.app.network_interface[0].nat_ip_address, null)
}

output "boot_disk_id" {
  description = "Идентификатор загрузочного диска."
  value       = yandex_compute_disk.boot.id
}

output "data_disk_id" {
  description = "Идентификатор сохраняемого диска данных."
  value       = yandex_compute_disk.data.id
}

output "ssh_command" {
  description = "Команда подключения, если NAT и SSH-доступ включены."
  value       = var.enable_nat ? "ssh ${var.vm_user}@${yandex_compute_instance.app.network_interface[0].nat_ip_address}" : null
}

