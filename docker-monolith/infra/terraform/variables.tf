variable cloud_id {
  description = "Cloud"
}
variable folder_id {
  description = "Folder"
}
variable zone {
  description = "Zone"
  default = "ru-central1-a"
}
variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable subnet_id {
  description = "Subnet"
}
variable service_account_key_file {
  description = "key.json"
}
variable private_key_path {
  description = "Path to the private key"
}
variable appcount {
  description = "Value for count"
  default     = 1
}
variable disk_image {
  description = "Disk image for reddit docker"
}
variable nmapp {
  description = "App name"
  default     = "reddit"
}
