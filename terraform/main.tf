# Main Terraform Configuration
terraform {
  required_version = ">= 1.9.0"
}

module "project_apis" {
  source     = "./modules/project_apis"
  project_id = var.project_id
}

module "artifact_registry" {
  source     = "./modules/artifact_registry"
  project_id = var.project_id
  region     = var.region

  depends_on = [module.project_apis]
}

module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id

  depends_on = [module.project_apis]
}

module "cloud_run" {
  source     = "./modules/cloud_run"
  project_id = var.project_id
  region     = var.region

  service_account_email = module.iam.service_account_email
  image_tag             = var.routing_engine_image_tag
  allow_unauthenticated = var.allow_public_routing_api

  depends_on = [module.artifact_registry, module.iam, module.project_apis]
}

module "gke" {
  source     = "./modules/gke"
  project_id = var.project_id
  region     = var.region

  depends_on = [module.project_apis]
}

module "developer_connect" {
  source                     = "./modules/developer_connect"
  project_id                 = var.project_id
  region                     = var.region
  github_app_installation_id = var.github_app_installation_id

  depends_on = [module.project_apis]
}
