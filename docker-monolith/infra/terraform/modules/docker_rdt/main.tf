resource "yandex_compute_instance" "docker_rdt" {
  name = "${var.name_app}-${count.index + 1}"

  labels = {
    tags = "${var.name_app}_${count.index + 1}"
  }

  count = var.appcount

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.disk_image
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}

locals {
  inst_ip = yandex_compute_instance.docker_rdt.*.network_interface.0.nat_ip_address
}

resource "local_file" "ansible_inventory" {
  content = templatefile(
                     "${path.module}/files/inventory.tpl",
                      {
                           namehost = var.name_app,
                           ipaddr = local.inst_ip

                      }
             )
  filename = "inventory.yml"

  provisioner "local-exec" {
    command = "mv inventory.yml ../ansible/inventory.yml"
  }

  provisioner "local-exec" {
    command = "ansible-playbook playbooks/docker_reddit.yml"
    working_dir = "../ansible"
  }
}
