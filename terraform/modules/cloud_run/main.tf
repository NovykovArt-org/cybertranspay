resource "google_cloud_run_service" "routing_engine" {
  name     = "routing-engine"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/cybertranspay/routing-engine:latest"
      }
    }
  }
}
