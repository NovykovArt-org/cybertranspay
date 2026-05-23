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

variable "routing_engine_image_tag" {
  description = "Docker image tag for routing-engine on Cloud Run"
  type        = string
  default     = "latest"
}

variable "allow_public_routing_api" {
  description = "Allow unauthenticated access to routing-engine (dev/MVP only)"
  type        = bool
  default     = false
}
