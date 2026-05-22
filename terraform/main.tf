# Enable required APIs
resource "google_project_service" "enabled_services" {
  for_each = toset([
    "container.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "aiplatform.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com"
  ])
  project = var.project_id
  service = each.key
}

# Artifact Registry
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "cybertranspay"
  description   = "CyberTransPay Docker repository"
  format        = "DOCKER"
}

# Cloud Run Service (Routing Engine)
resource "google_cloud_run_service" "routing_engine" {
  name     = "routing-engine"
  location = var.region

  template {
    spec {
      containers {
        image = "europe-west1-docker.pkg.dev/${var.project_id}/cybertranspay/routing-engine:latest"
        resources {
          limits = {
            cpu    = "2"
            memory = "4Gi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# GKE Autopilot Cluster (для высоконагруженных сервисов)
resource "google_container_cluster" "autopilot" {
  provider = google-beta
  name     = "cybertranspay-cluster"
  location = var.region

  enable_autopilot = true

  release_channel {
    channel = "REGULAR"
  }
}

# Service Account
resource "google_service_account" "cybertranspay_sa" {
  account_id   = "cybertranspay-sa"
  display_name = "CyberTransPay Service Account"
}
