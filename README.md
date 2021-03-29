# xeniaweber_microservices
xeniaweber microservices repository

## Homework 15
Для GitlabCI была создана виртуальная машина. Использую скрипт со следующим содержанием:
```console
#!/bin/bash

echo "Set VM name"
read vmname

echo "Set memory size"
read msize

echo "Set number of cores"
read ncore

echo "Set disk size"
read dsize

echo "Chose one value for disk type: 1.HDD, 2.SSD"
read dtype
case $dtype in
  1) d=$(printf "network-hdd") ;;
  2) d=$(printf "network-ssd") ;;
esac

echo "Chose one value for image-family: 1.ubuntu_18.04, 2.ubuntu_18.04_lts, 3.ubuntu_16.04_lts, 4.ubuntu_20.04_lts, 5.centos_6, 6.centos_7, 7.centos_8"
read image
case $image in
  1) n=$(printf "ubuntu-1804") ;;
  2) n=$(printf "ubuntu-1804-lts") ;;
  3) n=$(printf "ubuntu-1604-lts") ;;
  4) n=$(printf "ubuntu-2004-lts") ;;
  5) n=$(printf "centos-6") ;;
  6) n=$(printf "centos-7") ;;
  7) n=$(printf "centos-8") ;;
esac

yc compute instance create \
 --name $vmname \
 --zone ru-central1-a \
 --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
 --create-boot-disk image-folder-id=standard-images,image-family=$n,type=$d,size=$dsize> \
 --ssh-key ~/.ssh/yc_rsa.pub \
 --memory $msize \
 --cores $ncore
```
Используя **docker-machine** устанавливаю **docker** на созаднном инстансе. Для этого выполняю bash скрипт со следующим содержанием: 
```console
#!/bin/bash

echo "Set VM name"
read vmname

EXT_IP=$(yc compute instance get --name $vmname | sed -n '24p' | awk '{print $2}')

docker-machine create \
 --driver generic \
 --generic-ip-address=$EXT_IP \
 --generic-ssh-user yc-user \
 --generic-ssh-key ~/.ssh/yc_rsa \
docker-host
```
Создаю следующие директории:
```console
$ mkdir -p /srv/gitlab/{config,data,logs} 
```
В директории */srv/gitlab/* создаю файл **docker-compose.yml** со следующим содержимым:
```console
docker-compose.yml
web:
  image: 'gitlab/gitlab-ce:latest'
  restart: always
  hostname: 'gitlab.example.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'http://<YOUR-VM-IP>'
  ports:
    - '80:80'
    - '443:443'
    - '2222:22'
  volumes:
    - '/srv/gitlab/config:/etc/gitlab'
    - '/srv/gitlab/logs:/var/log/gitlab'
    - '/srv/gitlab/data:/var/opt/gitlab'
```
После успешного запуска контейнера могу видеть **GitlabCI**, если в браузере перейду по адресу VM - http://EXT_IP_VM

В GitlabCI создан проект со следующим пайпланом для CI/CD: [.gitlab-ci.yml](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/gitlab-ci-1/.gitlab-ci.yml). При каждом push в репозиторий скрипт отрабатывает и согласно своему содержимому, проходит блоки: **build -> test -> review -> stage -> production**. Последние два не обязательны, а именно запускаются вручную при необходимости. Для этого используется *when: manual*. Автоматический сценарий выглядит как: *запуск билда -> тестирование -> деплой в dev*. При тестировании также вызывается скрипт [simpletest.rb](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/gitlab-ci-1/reddit/simpletest.rb).  
**Важно!!!** пайплайн должен на чем-то запускаться. Для этого необходимо добавить и зарегистрировать **Runner**, на котором будет запускаться все.

 ### Задание со *
 Написан скрипт для автоматического добавления раннера.
 - [autoaddrunner.shj](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/gitlab-ci-1/gitlab-ci/autoaddrunner.sh) 
  
 Скрипт собирает данные о VM, куда нужно установить и с помощью псевдотерминала по ssh выполняет следующий скрипт:
 - [addreg.sh](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/gitlab-ci-1/gitlab-ci/addreg.sh)


## Homework 14
### Самостоятельное задание
### 1. Изменить docker-compose под кейс с множеством сетей (back_net, front_net)
В **docker_compose** файл создаю сети **front_net** и **back_net**:
```console
networks:
  back_net:
     driver: bridge
     ipam:
       driver: default
       config:
         - subnet: 10.0.2.0/24
  front_net:
     driver: bridge
     ipam:
       driver: default
       config:
         - subnet: 10.0.1.0/24
```
Далее в разделе **network** для каждого сервиса указываю необходимую сеть. Так, например, для **ui** указана **front_net**, а для **post** указаны **front_net** и **back_net**.
### 2. Параметризировать с помощью переменных окружения:
- Порт публикации сервиса **ui**
Порты указываются в разделе **ports**, порт публикации указывается первым. Параметризирую его. Итого для сервиса **ui** получаю следующую запись:
```console
ports:
      - ${PORT_UI}:9292/tcp
```
- Версии сервисов
Для **post_db**:
```console
image: mongo:${TAG_MONGO}
```
Для **ui**:
```console
image: ${USERNAME}/ui:${TAG_UI}
```
Для **post**:
```console
image: ${USERNAME}/post:${TAG_UI}
```
Для **comment**:
```console
image: ${USERNAME}/comment:${TAG_UI}
```
- На свое усмотрение:   
Путь к контексту сборки:
```console
ui:
    build: ./${BUILD_UI}
-----------------------------
post:
    build: ./${BUILD_POST}
-----------------------------
comment:
    build: ./${BUILD_COMMENT}
```
Путь к волюму для **post_db**:
```console
volumes:
      - post_db:${VOL_PATH_PD}
```
### 3. Праметризированные параметры записать в файл .env
Создан файл [.env](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-4/src/.env.example)
Закоммичен в репозиторий как **.env.examnple**
### 4. Запуск образа без исопльзования export и source
Запускаю **docker compose** командой:
```console
$ docker-compose up -d
```
Переменные подтягиваются из **.env**  
В итоге получается такой [docker-compose.yml](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-4/src/docker-compose.yml) файл

### Имя проекта
Базовое имя проекта образуется следующим образом - *<имя-директории>_<имя-контейнера>_<индекс>* 
Чтобы задать имя проекта можно использовать опцию **-p, --project-name NAME** при запуске **docker-compose**

### Задание со *
Для того, чтобы запустить код приложения без сборки образа, применяю опции (например, указание переменных окружения, как в прошлом ДЗ) и убираю опцию **build**
Как раз запуск **puma** c необходимыми опциями (дебаг и два воркера) - внесение изменений. В докерфайлах сервис **puma** запускается без опций. В **docker-compose** файл добавлю для сервисов опцию **comand**, в которой укажу каким образом мне нужно запустить **puma**. Получаю на примере **comment**:
```console
 comment:
  #  build: ./${BUILD_COMMENT}
    image: ${USERNAME}/comment:${TAG_COMMENT}
    networks:
      - back_net
      - front_net
    command: ["puma", "-w", "2", "--debug"]
```
В итоге вышел следующий [docker-compose.override.yml](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-4/src/docker-compose.override.yml)

## Homework 13
### Сборка приложений
Для микросервисов были написаны докерфайлы:
- [Dockerfile](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-3/src/post-py/Dockerfile) - для **post-py**
- [Dockerfile](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-3/src/comment/Dockerfile) - для **comment**
- [Dockerfile](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-3/src/ui/Dockerfile) - для **ui**
При билде образов замечаю, что **ui** начинает сборку не с первого шага. Причиной является сборка **comment** сделанная раннее. У **comment** и **ui** первые шаги одинаковые и нет необходимости их делать два раза. Во время сборки **ui** результат первых шагов берется из кэша. Т.е. эти слои уже существуют в системе.

### Задание со * №1
Для запуска контейнеров с другими алиасами, но без пересборки образа использую аргумент **-e** для **docker run**. С помощью данного аргумента я могу объявить переменные окружения. Так, например, если я меняю для **post** алиас - **--network-alias=post0**, то для **ui** при запуске контейнера указываю переменную окржуения **-e POST_SERVICE_HOST=post0**. Для полного запуска с другими алиасами написан скрипт - [docker-run-env.sh](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-3/docker-run-env.sh)

### Задание со * №2
Докер образы могут весить много. Для оптимизации были внесены изменения в докерфайлы **сommit** и **ui**:
- Образ **alpine** более леговесный
```console
 FROM alpine
 ```
- Так как ранее использовался образ **ruby**, а теперь **alpine**, необходимо установить **ruby**. Использую **--no-cache**, для установки **bundler** отменяю документацию **--no-document**. После всех установоки очищаю индекс пакета при помощи *rm -rf /var/cache/apk/*. Итого:
```console
RUN apk update --no-cache \
&& apk add --no-cache ruby-full ruby-dev build-base \
&& gem install bundler:1.17.2 --no-document \
&& rm -rf /var/cache/apk/*
```
- После всей сборки удаляю **buil-base** (поняла уже при описании ДЗ, что также можно было удалить что-то еще, кроме этого пакета):
```console
RUN apk del build-base
```
- [Dockerfile1](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-3/src/comment/Dockerfile1) для **comment**
- [Dockerfile1](https://github.com/Otus-DevOps-2020-11/xeniaweber_microservices/blob/docker-3/src/ui/Dockerfile) для **ui**

### Хранение данных
Если остановить контейнеры и заново запустить, все изменения, сделанные до остановки, не сохранятся. Для хранения данных исполюзуются волюмы. Так как внесенные изменения хранятя в БД, создадим волюм для контейнера **mongo:latest**:
```console
$ docker volume create reddit_db
```
И запустим контейнер с волюмом:
```console
$ docker run -d --network=reddit \
   --network-alias=post_db \
   --network-alias=comment_db \ 
   -v reddit_db:/data/db \
  mongo:latest
```
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
