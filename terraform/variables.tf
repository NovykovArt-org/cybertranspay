variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "cybertranspay-prod"
}

variable "region" {
  description = "Default region"
  type        = string
  default     = "europe-west1"
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID for Developer Connect"
  type        = number
  default     = 0
}
