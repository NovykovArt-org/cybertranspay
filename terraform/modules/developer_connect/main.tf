resource "google_developer_connect_connection" "github" {
  provider      = google-beta
  connection_id = "cybertranspay-github"
  location      = var.region

  github_config {
    github_app          = "DEVELOPER_CONNECT"
    app_installation_id = var.github_app_installation_id
  }
}
