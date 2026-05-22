terraform {
  required_version = ">= 1.9.0"

  backend "gcs" {
    bucket         = "cybertranspay-terraform-state"
    prefix         = "terraform/state"
    location       = "europe-west1"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.10.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.10.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}
