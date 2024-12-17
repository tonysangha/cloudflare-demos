terraform {
  required_providers {
    google = {
      version = "~> 6.14.0"
    }
  }
}

provider "google" {

  project = var.gcp_project
}