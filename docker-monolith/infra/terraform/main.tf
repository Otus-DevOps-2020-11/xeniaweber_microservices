provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone

}
module "docker_rdt" {
  source          = "./modules/docker_rdt"
  public_key_path = var.public_key_path
  disk_image      = var.disk_image
  subnet_id       = var.subnet_id
  name_app        = var.nmapp
  private_key     = var.private_key_path
  appcount        = var.appcount
}
