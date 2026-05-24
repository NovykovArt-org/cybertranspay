resource "google_container_cluster" "autopilot" {
  provider         = google-beta
  name             = "cybertranspay-cluster"
  location         = var.region
  project          = var.project_id
  enable_autopilot = true
}
