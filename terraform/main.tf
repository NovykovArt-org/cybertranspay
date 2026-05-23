terraform {
  required_version = ">= 1.9.0"

  backend "gcs" {
    bucket = "cybertranspay-terraform-state"
    prefix = "terraform/state"
  }
}

module "artifact_registry" {
  source     = "./modules/artifact_registry"
  project_id = var.project_id
  region     = var.region
}

module "cloud_run" {
  source     = "./modules/cloud_run"
  project_id = var.project_id
  region     = var.region
}

module "gke" {
  source     = "./modules/gke"
  project_id = var.project_id
  region     = var.region
}

# module "developer_connect" {          # Временно отключен
#   source = "./modules/developer_connect"
# }

module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id
}
