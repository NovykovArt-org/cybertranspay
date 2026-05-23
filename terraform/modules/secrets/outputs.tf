output "api_keys_secret_id" {
  value = var.create_api_key_secret ? google_secret_manager_secret.api_keys[0].secret_id : ""
}
