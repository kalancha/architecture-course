# Идентификаторы не являются секретами, но плейсхолдеры необходимо заменить.
cloud_id  = "b1g637pfbt3lqmmf7dsf"
folder_id = "b1gcc5h9msrgvju9lvgh"

zone        = "ru-central1-a"
environment = "study"
name_prefix = "future20"

subnet_cidr = "10.20.10.0/24"
enable_nat  = true

# Безопасное значение по умолчанию: входящий SSH закрыт.
# Перед проверкой можно указать только свой публичный адрес: ["198.51.100.10/32"].
allowed_ssh_cidrs = []

platform_id      = "standard-v3"
vm_cores         = 2
vm_memory_gb     = 2
vm_core_fraction = 20

image_family      = "ubuntu-2404-lts"
disk_type         = "network-hdd"
boot_disk_size_gb = 15
data_disk_size_gb = 20

vm_user             = "future-admin"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
