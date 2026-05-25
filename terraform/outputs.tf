output "routing_engine_url" {
  description = "Cloud Run URL for the routing engine API"
  value       = module.cloud_run.service_url
}

output "artifact_registry_docker" {
  description = "Docker repository prefix for images"
  value       = module.artifact_registry.docker_repository
}

output "service_account_email" {
  description = "Runtime service account for CyberTransPay workloads"
  value       = module.iam.service_account_email
}
