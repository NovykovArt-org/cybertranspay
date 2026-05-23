resource "google_container_cluster" "autopilot" {
  provider         = google-beta
  name             = "cybertranspay-cluster"
  location         = var.region
  enable_autopilot = true
}
