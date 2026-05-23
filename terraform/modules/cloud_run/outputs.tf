output "service_url" {
  description = "Public URL of the routing-engine Cloud Run service"
  value       = google_cloud_run_service.routing_engine.status[0].url
}

output "service_name" {
  value = google_cloud_run_service.routing_engine.name
}
