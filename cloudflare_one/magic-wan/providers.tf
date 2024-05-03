terraform {
  required_providers {
    google = {
      version = "~> 5.0.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "google" {

  project = var.gcp_project
}

provider "cloudflare" {
  # api_token = var.cloudflare_api_token
  api_key = var.cloudflare_api_key
  email   = var.cloudflare_email
}