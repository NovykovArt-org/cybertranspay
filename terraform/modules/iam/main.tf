resource "google_service_account" "main" {
  project      = var.project_id
  account_id   = "cybertranspay-sa"
  display_name = "CyberTransPay Main Service Account"
}

resource "google_project_iam_member" "run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.main.email}"
}

resource "google_project_iam_member" "artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.main.email}"
}
