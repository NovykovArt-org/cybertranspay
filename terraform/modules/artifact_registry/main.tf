resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "cybertranspay"
  description   = "CyberTransPay Docker images"
  format        = "DOCKER"
}
