data "google_project" "current" {
  project_id = var.project_id
}

locals {
  project_number  = data.google_project.current.number
  cloudbuild_sa   = "${local.project_number}@cloudbuild.gserviceaccount.com"
  compute_sa      = "${local.project_number}-compute@developer.gserviceaccount.com"
  cloud_run_robot = "service-${local.project_number}@serverless-robot-prod.iam.gserviceaccount.com"
}

# Cloud Build SA — used by GitHub triggers and regional builds
resource "google_project_iam_member" "cloudbuild_artifactregistry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${local.cloudbuild_sa}"
}

resource "google_project_iam_member" "cloudbuild_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${local.cloudbuild_sa}"
}

resource "google_project_iam_member" "cloudbuild_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${local.cloudbuild_sa}"
}

resource "google_project_iam_member" "cloudbuild_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.cloudbuild_sa}"
}

# Compute default SA — used by manual `gcloud builds submit` in some setups
resource "google_project_iam_member" "compute_artifactregistry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${local.compute_sa}"
}

resource "google_project_iam_member" "compute_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${local.compute_sa}"
}

resource "google_project_iam_member" "compute_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.compute_sa}"
}

resource "google_iam_service_account_iam_member" "compute_act_as_self" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${local.compute_sa}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.compute_sa}"
}

# Cloud Run needs to pull images from Artifact Registry
resource "google_project_iam_member" "cloud_run_robot_artifactregistry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${local.cloud_run_robot}"
}

resource "google_cloudbuild_trigger" "routing_engine_main" {
  count = var.create_trigger ? 1 : 0

  name        = "${var.service_name}-main"
  description = "Build and update ${var.service_name} on push to main"
  location    = var.region
  project     = var.project_id

  github {
    owner = var.github_owner
    name  = var.github_repo
    push {
      branch = var.branch_pattern
    }
  }

  filename = var.build_config
}
