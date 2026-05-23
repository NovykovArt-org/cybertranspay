resource "google_cloud_run_service" "routing_engine" {
  name     = "routing-engine"
  location = var.region
  project  = var.project_id

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = tostring(var.min_instances)
      }
    }
    spec {
      service_account_name = var.service_account_email != "" ? var.service_account_email : null

      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}/routing-engine:${var.image_tag}"

        ports {
          container_port = 8080
        }

        env {
          name  = "RUST_LOG"
          value = "info"
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].image,
    ]
  }
}

resource "google_cloud_run_service_iam_member" "public_invoker" {
  count    = var.allow_unauthenticated ? 1 : 0
  service  = google_cloud_run_service.routing_engine.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}
