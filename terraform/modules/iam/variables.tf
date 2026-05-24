variable "project_id" {
  type = string
}

variable "project_number" {
  type        = string
  description = "GCP project number (for Cloud Build SA IAM)"
  default     = "1079379369218"
}
