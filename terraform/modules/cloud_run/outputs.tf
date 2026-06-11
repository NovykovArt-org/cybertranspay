output "service_url" {
  description = "Public URL of the routing-engine Cloud Run service"
  value       = google_cloud_run_v2_service.routing_engine.uri
}

output "service_name" {
  value = google_cloud_run_v2_service.routing_engine.name
}

output "persistence_bucket_name" {
  value = var.enable_persistence ? google_storage_bucket.routing_engine_data[0].name : null
}
