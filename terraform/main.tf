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

module "cloud_build" {
  source     = "./modules/cloud_build"
  project_id = var.project_id
  region     = var.region

  github_owner   = var.github_owner
  github_repo    = var.github_repo
  create_trigger = var.create_cloud_build_trigger
}
