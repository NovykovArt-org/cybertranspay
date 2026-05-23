terraform {
  backend "gcs" {
    bucket        = "cybertranspay-terraform-state"
    prefix        = "terraform/state"
    location      = "europe-west1"
    storage_class = "STANDARD"
  }
}
