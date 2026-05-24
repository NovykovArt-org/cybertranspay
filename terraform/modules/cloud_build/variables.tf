variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "github_owner" {
  type    = string
  default = "NovykovArt-org"
}

variable "github_repo" {
  type    = string
  default = "cybertranspay"
}

variable "branch_pattern" {
  type    = string
  default = "^main$"
}

variable "build_config" {
  type    = string
  default = "cloudbuild.yaml"
}

variable "create_trigger" {
  type        = bool
  default     = false
  description = "Set true after GitHub is connected to Cloud Build in GCP Console."
}

variable "service_name" {
  type    = string
  default = "routing-engine"
}
