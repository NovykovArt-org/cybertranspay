resource "google_beta_developer_connect_connection" "github" {
  connection_id = "cybertranspay-github"
  location      = var.region

  github_config {
    app_installation_id = var.github_app_installation_id
  }

  description = "GitHub connection for cybertranspay"
}
