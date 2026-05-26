variable "project_id" {
  type    = string
  default = "cybertranspay-prod"
}

variable "region" {
  type    = string
  default = "europe-west1"
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

variable "enable_routing_engine_persistence" {
  description = "Mount a Cloud Storage bucket into Cloud Run for quote/transfer JSON persistence"
  type        = bool
  default     = true
}

variable "routing_engine_persistence_bucket_name" {
  description = "Optional explicit Cloud Storage bucket name for routing-engine persistence"
  type        = string
  default     = ""
}
