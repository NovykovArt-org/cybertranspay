output "cloudbuild_service_account" {
  value = "${data.google_project.current.number}@cloudbuild.gserviceaccount.com"
}

output "trigger_id" {
  value       = try(google_cloudbuild_trigger.routing_engine_main[0].trigger_id, null)
  description = "Set create_trigger = true after connecting GitHub to Cloud Build."
}
