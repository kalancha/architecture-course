variable "cloud_id" {
  description = "Идентификатор облака Yandex Cloud. Не является секретом."
  type        = string

  validation {
    condition     = length(trimspace(var.cloud_id)) > 0 && !startswith(var.cloud_id, "REPLACE_")
    error_message = "Укажите реальный cloud_id в terraform.tfvars."
  }
}

variable "folder_id" {
  description = "Идентификатор изолированного учебного каталога Yandex Cloud. Не является секретом."
  type        = string

  validation {
    condition     = length(trimspace(var.folder_id)) > 0 && !startswith(var.folder_id, "REPLACE_")
    error_message = "Укажите реальный folder_id в terraform.tfvars."
  }
}

variable "zone" {
  description = "Зона доступности ресурсов."
  type        = string
  default     = "ru-central1-a"
}

variable "environment" {
  description = "Метка окружения."
  type        = string
  default     = "study"
}

variable "name_prefix" {
  description = "Единый префикс имён ресурсов."
  type        = string
  default     = "future20"
}

variable "subnet_cidr" {
  description = "CIDR прикладной подсети."
  type        = string
  default     = "10.20.10.0/24"
}

variable "allowed_ssh_cidrs" {
  description = "Список доверенных CIDR для SSH. Пустой список полностью закрывает входящий SSH."
  type        = list(string)
  default     = []
}

variable "enable_nat" {
  description = "Выдать ВМ динамический публичный IP через NAT."
  type        = bool
  default     = true
}

variable "platform_id" {
  description = "Аппаратная платформа Compute Cloud."
  type        = string
  default     = "standard-v3"
}

variable "vm_cores" {
  description = "Количество vCPU учебной ВМ."
  type        = number
  default     = 2

  validation {
    condition     = var.vm_cores >= 2
    error_message = "Для standard-v3 задайте не менее 2 vCPU."
  }
}

variable "vm_memory_gb" {
  description = "Объём RAM учебной ВМ в ГБ."
  type        = number
  default     = 2

  validation {
    condition     = var.vm_memory_gb >= 2
    error_message = "Задайте не менее 2 ГБ RAM."
  }
}

variable "vm_core_fraction" {
  description = "Гарантированная доля производительности vCPU в процентах."
  type        = number
  default     = 20

  validation {
    condition     = contains([20, 50, 100], var.vm_core_fraction)
    error_message = "Допустимые учебные значения: 20, 50 или 100."
  }
}

variable "image_family" {
  description = "Семейство публичного образа ОС."
  type        = string
  default     = "ubuntu-2404-lts"
}

variable "disk_type" {
  description = "Тип сетевых дисков."
  type        = string
  default     = "network-hdd"
}

variable "boot_disk_size_gb" {
  description = "Размер загрузочного диска в ГБ."
  type        = number
  default     = 15

  validation {
    condition     = var.boot_disk_size_gb >= 15
    error_message = "Размер загрузочного диска должен быть не меньше 15 ГБ."
  }
}

variable "data_disk_size_gb" {
  description = "Размер отдельного диска данных в ГБ."
  type        = number
  default     = 20

  validation {
    condition     = var.data_disk_size_gb >= 10
    error_message = "Размер диска данных должен быть не меньше 10 ГБ."
  }
}

variable "vm_user" {
  description = "Непривилегированный пользователь, создаваемый cloud-init."
  type        = string
  default     = "future-admin"
}

variable "ssh_public_key_path" {
  description = "Локальный путь к публичному SSH-ключу. В репозиторий ключ не копируется."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

