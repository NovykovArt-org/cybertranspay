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

output "routing_engine_persistence_bucket" {
  description = "Cloud Storage bucket mounted into Cloud Run for quote/transfer persistence"
  value       = module.cloud_run.persistence_bucket_name
}
