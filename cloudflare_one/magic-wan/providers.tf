terraform {
  required_providers {
    google = {
      version = "~> 5.0.0"
    }
  }
}

provider "google" {

  project = var.gcp_project
}