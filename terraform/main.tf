# Main Terraform Configuration
terraform {
  required_version = ">= 1.9.0"
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
  depends_on = [module.artifact_registry]
}

module "gke" {
  source     = "./modules/gke"
  project_id = var.project_id
  region     = var.region
}

module "developer_connect" {
  source                     = "./modules/developer_connect"
  project_id                 = var.project_id
  region                     = var.region
  github_app_installation_id = var.github_app_installation_id
}

module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id
}
