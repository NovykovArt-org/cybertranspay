resource "google_secret_manager_secret" "api_keys" {
  count     = var.create_api_key_secret ? 1 : 0
  project   = var.project_id
  secret_id = "routing-engine-api-keys"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "api_keys" {
  count       = var.create_api_key_secret && var.api_keys != "" ? 1 : 0
  secret      = google_secret_manager_secret.api_keys[0].id
  secret_data = var.api_keys
}

resource "google_secret_manager_secret_iam_member" "cloud_run_accessor" {
  count     = var.create_api_key_secret && var.service_account_email != "" ? 1 : 0
  project   = var.project_id
  secret_id = google_secret_manager_secret.api_keys[0].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}
