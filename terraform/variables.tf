variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "cybertranspay"
}

variable "project_number" {
  description = "GCP project number"
  type        = string
  default     = "1079379369218"
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
  description = "Allow unauthenticated Cloud Run invoke (dev/MVP only)"
  type        = bool
  default     = false
}

variable "auth_required" {
  description = "Require X-API-Key header on /v1/* routes"
  type        = bool
  default     = true
}

variable "auth_api_keys" {
  description = "Comma-separated API keys stored in Secret Manager"
  type        = string
  sensitive   = true
  default     = ""
}

variable "create_auth_secret" {
  description = "Create Secret Manager secret for AUTH_API_KEYS"
  type        = bool
  default     = true
}
