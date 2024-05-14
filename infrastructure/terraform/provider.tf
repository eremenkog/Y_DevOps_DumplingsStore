terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.61.0"
    }
  }

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "nk-dumpling-bucket"
    region     = "ru-central1"
    key        = "terraform/terraform.tfstate"
    access_key = "YCAJEivf1DZVGeeLWKX1ZRA6M"
  # secret_key in backend.tfvars

    skip_region_validation      = true
    skip_credentials_validation = true
  }
} 

provider "yandex" {
  token     = var.iam_token #secret.tfvars
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}