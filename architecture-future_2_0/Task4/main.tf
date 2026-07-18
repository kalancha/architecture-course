terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.206.0"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

locals {
  common_labels = {
    project     = "future-2-0"
    environment = var.environment
    managed_by  = "terraform"
  }
}

data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

resource "yandex_vpc_network" "main" {
  name        = "${var.name_prefix}-network"
  description = "Учебная сеть проекта Будущее 2.0"
  labels      = local.common_labels
}

resource "yandex_vpc_subnet" "main" {
  name           = "${var.name_prefix}-subnet"
  description    = "Подсеть прикладного контура"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_cidr]
  labels         = local.common_labels
}

resource "yandex_vpc_security_group" "vm" {
  name        = "${var.name_prefix}-vm-sg"
  description = "Минимально необходимые сетевые правила учебной ВМ"
  network_id  = yandex_vpc_network.main.id
  labels      = local.common_labels

  ingress {
    description    = "Взаимодействие компонентов внутри подсети"
    protocol       = "ANY"
    v4_cidr_blocks = [var.subnet_cidr]
  }

  dynamic "ingress" {
    for_each = length(var.allowed_ssh_cidrs) == 0 ? [] : [1]

    content {
      description    = "SSH только из явно разрешённых сетей"
      protocol       = "TCP"
      port           = 22
      v4_cidr_blocks = var.allowed_ssh_cidrs
    }
  }

  egress {
    description    = "Исходящий доступ для обновлений и внешних API"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_disk" "boot" {
  name        = "${var.name_prefix}-boot-disk"
  description = "Загрузочный диск прикладной ВМ"
  type        = var.disk_type
  zone        = var.zone
  size        = var.boot_disk_size_gb
  image_id    = data.yandex_compute_image.ubuntu.id
  labels      = local.common_labels
}

resource "yandex_compute_disk" "data" {
  name        = "${var.name_prefix}-data-disk"
  description = "Отдельный диск для прикладных данных"
  type        = var.disk_type
  zone        = var.zone
  size        = var.data_disk_size_gb
  labels      = local.common_labels
}

resource "yandex_compute_instance" "app" {
  name                      = "${var.name_prefix}-app-vm"
  hostname                  = "${var.name_prefix}-app"
  description               = "Учебная IaaS-ВМ для проверки Terraform-контура"
  platform_id               = var.platform_id
  zone                      = var.zone
  allow_stopping_for_update = true
  labels                    = local.common_labels

  resources {
    cores         = var.vm_cores
    memory        = var.vm_memory_gb
    core_fraction = var.vm_core_fraction
  }

  boot_disk {
    disk_id     = yandex_compute_disk.boot.id
    auto_delete = true
  }

  secondary_disk {
    disk_id     = yandex_compute_disk.data.id
    device_name = "data"
    auto_delete = false
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.main.id
    nat                = var.enable_nat
    security_group_ids = [yandex_vpc_security_group.vm.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      vm_user        = var.vm_user
      ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
    })
  }
}

