locals {
  persistence_bucket_name = var.persistence_bucket_name != "" ? var.persistence_bucket_name : "${var.project_id}-routing-engine-data"
}

resource "google_storage_bucket" "routing_engine_data" {
  count = var.enable_persistence ? 1 : 0

  name                        = local.persistence_bucket_name
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}

resource "google_storage_bucket_iam_member" "routing_engine_data_writer" {
  count = var.enable_persistence && var.service_account_email != "" ? 1 : 0

  bucket = google_storage_bucket.routing_engine_data[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"
}

resource "google_cloud_run_v2_service" "routing_engine" {
  name     = "routing-engine"
  location = var.region
  project  = var.project_id

  template {
    service_account = var.service_account_email != "" ? var.service_account_email : null

    scaling {
      min_instance_count = var.min_instances
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}/routing-engine:${var.image_tag}"

      ports {
        container_port = 8080
      }

      env {
        name  = "RUST_LOG"
        value = "info"
      }

      env {
        name  = "AUTH_REQUIRED"
        value = var.auth_required ? "true" : "false"
      }

      dynamic "env" {
        for_each = var.api_keys_secret_id != "" ? [1] : []
        content {
          name = "AUTH_API_KEYS"
          value_source {
            secret_key_ref {
              secret  = var.api_keys_secret_id
              version = "latest"
            }
          }
        }
      }

      dynamic "env" {
        for_each = var.enable_persistence ? [1] : []
        content {
          name  = "CTP_DATA_DIR"
          value = var.persistence_mount_path
        }
      }

      dynamic "volume_mounts" {
        for_each = var.enable_persistence ? [1] : []
        content {
          name       = "routing-engine-data"
          mount_path = var.persistence_mount_path
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    dynamic "volumes" {
      for_each = var.enable_persistence ? [1] : []
      content {
        name = "routing-engine-data"
        gcs {
          bucket    = google_storage_bucket.routing_engine_data[0].name
          read_only = false
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count    = var.allow_unauthenticated ? 1 : 0
  name     = google_cloud_run_v2_service.routing_engine.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}
