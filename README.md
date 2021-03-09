# xeniaweber_microservices
xeniaweber microservices repository
## Homework 12
### Задание со * №1
Сравнила вывод двух команд:
```console
$ docker inspect <u_container_id> > inspect_container
$ docker insepct <u_image_id> inspect_image
$ diff -y inspect_container inspect_image
```
Объяснила отличие между контейнером и образом, описание внесла в файл [docker-1.log](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/docker-1.log)

### Задание со * №2
### Конфигурация Ansible
- Написаны два плейбука **Ansbile**: один для установки **Docker** - *docker_install.yml*, другой для старта контейнера на основе созданного образа - *docker_reddit.yml*.
  - [docker_install.yml](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/ansible/playbooks/docker_install.yml) - будет использован для *provisioner* **Packer**. В плейбуке используется созданная роль [docker](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/ansible/roles/docker), со следующими тасками в [tasks/main.yml](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/ansible/roles/docker/tasks/main.yml):
  ```console
  - name: Install packages to use apt over HTTPS
    apt:
     pkg:
     - apt-transport-https
     - ca-certificates
     - curl
     - gnupg
     - python-pip
     update_cache: yes

   - name: Install Docker SDK for Python <--- Необходимо для дальнейшего использования модуля docker_container в плейбуке
     pip:
      name: docker
     executable: pip

   - name: Add docker GPG key
     apt_key:
      url: https://download.docker.com/linux/ubuntu/gpg
      state: present

   - name: Add docker repository
     apt_repository:
       repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable
       state: present
       update_cache: yes

    - name:
      apt:
       pkg:
       - docker-ce
       - docker-ce-cli
       - containerd.io
       update_cache: yes
      notify: systemd docker <-- Вызов хэндлэра
  ```
  Описание хэндлэра находится в [handlers/main.yml](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/ansible/roles/docker/handlers/main.yml):
  ```console
  - name: systemd docker
  systemd: name=docker state=started enabled=yes
  ```
  - [docker_reddit.yml](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/ansible/playbooks/docker_reddit.yml) - будет использован для *provisioner* **Terraform**. В плейбуке используется созданная роль [docker_reddit](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/ansible/roles/docker_reddit), со следующими тасками в [tasks/main.yml](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/ansible/roles/docker_reddit/tasks/main.yml) для старта контейнера:
  ```console
  - name: Run docker container reddit
  docker_container:
    name: reddit
    image: xweber/otus-reddit:1.0 <--- Cозданный ранее образ из Dockerfile
    state: started
    ports:
    - "9292:9292"
  ```
  Для **Ansbile** написана следующая конфигурация в файле [ansible.cfg](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/ansible/ansible.cfg). Инвентори файл генерируется при помощи **Terraform** при создании истансов.

### Конфигурация Packer
 Написан шаблон [docker.json](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/packer/docker.json) для создания образа с установленным **Docker**. Для установки используется вызов плейбука [docker_install.yml](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/ansible/playbooks/docker_install.yml) в *provison*:
 ```console
 "provisioners": [
        {
             "type": "ansible",
             "playbook_file": "ansible/playbooks/docker_install.yml",
             "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
         }
    ]
 ```
Также написан файл для определения переменных [variables.json](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/packer/variables.json).
Для созадния образа гененрирую IAM токен для сервисного аккаунта, от имени которого буду выполнять следующие дейтсвия. Для этого вызываю команду:
```console
$ yc iam key create --service-account-name srv_acc --output key.json
```
Далее создаю образ. Команду выполняю из корня, верней из диретории [infra](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra):
```console
$ packer build -var-file=packer/variables.json packer/docker.json
```

### Конфигурация Terraform
  Написан конфигурационный файл [main.tf](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/terraform/main.tf) c обращением к модулю [docker_rdt]((https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/terraform/modules/docker_rdt):
  ```console
  module "docker_rdt" {
    source          = "./modules/docker_rdt"
    public_key_path = var.public_key_path
    disk_image      = var.disk_image
    subnet_id       = var.subnet_id
    name_app        = var.nmapp
    private_key     = var.private_key_path
    appcount        = var.appcount
  }
  ```
  Для модуля написан конфигурационный файл [main.tf](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/terraform/modules/docker_rdt/main.tf), в котором при помощи *provisioner* вызывется плейбук [docker_reddit.yml](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/ansible/playbooks/docker_reddit.yml) для старта контейнера:
  ```console
  provisioner "local-exec" {
    command = "ansible-playbook playbooks/docker_reddit.yml"
    working_dir = "../ansible"
  }
  ```
  Также в ходе данной конфигурации генерируется инвентори для **Ansible** при вызове шаблона при помощи *templatefile*:
  ```console
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
  ```
  Файл шаблона [invetory.tpl] выглядит следюущим образом:
  ```console
  docker_reddit:
   hosts:
  %{ for i,name in ipaddr ~}
      ${namehost}-${i + 1}:
         ansible_host: ${name}
  %{ endfor~ }
  ```
  Сгенерированный файл [inventory.yml](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/ansible/inventory.yml) выглядит примерно так:
  ```console
  docker_reddit:
  hosts:
    reddit-0:
         ansible_host: 84.252.129.164
    reddit-1:
         ansible_host: 84.201.132.10
  ```
  Полученный файл перемещается в директорю **ansible** при помощи *provisioner*
  ```console
  provisioner "local-exec" {
    command = "mv inventory.yml ../ansible/inventory.yml"
  }
  ```
  Перед тем, как запустить конфигурацию, необходимо указать созданный раннее образ **Packer**. За обращение к образу отвечает переменная *var.disk_image*. В файле [terraform.tfvars](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-2/docker-monolith/infra/terraform/terraform.tfvars.example) указываю для переменной *disk_image* **id** созданного образа:
  ```console
  disk_image               = "fd866c1ja8ccnc4qnnl8"
  ```
  Далее, для создания инстансов выполняю:
  ```console
  $ terraform init
  $ terraform plan
  $ terraform apply --auto-approve
  ```
  ### Структуры 
  - **Ansible**:
  ```console
  $ tree ansible/
  ansible/
  ├── ansible.cfg
  ├── inventory.yml
  ├── playbooks
  │   ├── docker_install.yml
  │   └── docker_reddit.yml
  └── roles
      ├── docker
      │   ├── defaults
      │   ├── files
      │   ├── handlers
      │   ├── meta
      │   ├── README.md
      │   ├── tasks
      │   ├── templates
      │   ├── tests
      │   └── vars
      └── docker_reddit
          ├── defaults
          ├── files
          ├── handlers
          ├── meta
          ├── README.md
          ├── tasks
          ├── templates
          ├── tests
          └── vars
  ```
  - **Teraform**:
  ```console
  $ tree terraform
    terraform/
    ├── main.tf
    ├── modules
    │   └── docker_rdt
    │       ├── files
    │       │   └── inventory.tpl
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── outputs.tf
    ├── terraform.tfstate
    ├── terraform.tfvars.example
    └── variables.tf
  ```
  - **Packer**
  ```console
  $ tree packer
  packer/
  ├── docker.json
  └── variables.json

  ```
