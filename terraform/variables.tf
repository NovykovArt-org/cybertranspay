variable "project_id" {
  type    = string
  default = "cybertranspay-prod"
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "github_app_installation_id" {
  type      = string
  sensitive = true
}
