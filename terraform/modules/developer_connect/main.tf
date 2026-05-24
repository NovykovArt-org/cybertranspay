resource "google_developer_connect_connection" "github" {
  count         = var.github_app_installation_id > 0 ? 1 : 0
  provider      = google-beta
  connection_id = "cybertranspay-github"
  location      = var.region
  project       = var.project_id

  github_config {
    github_app          = "DEVELOPER_CONNECT"
    app_installation_id = var.github_app_installation_id
  }
}
