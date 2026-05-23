variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "github_app_installation_id" {
  type        = number
  description = "GitHub App installation ID for Developer Connect"
  default     = 0
}
