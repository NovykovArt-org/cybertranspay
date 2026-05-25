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

variable "github_owner" {
  type    = string
  default = "NovykovArt-org"
}

variable "github_repo" {
  type    = string
  default = "cybertranspay"
}

variable "create_cloud_build_trigger" {
  type        = bool
  default     = false
  description = "Enable after GitHub is linked in Cloud Build Console."
}
