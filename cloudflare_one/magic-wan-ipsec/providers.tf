terraform {
  required_providers {
    google = {
      version = "~> 6.14.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.48.0"
    }
  }

  # Use Cloudflare R2 to store state file
  backend "s3" {
    bucket                      = ""
    key                         = ""
    region                      = ""
    profile                     = ""
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

provider "google" {

  project = var.gcp_project
}

provider "cloudflare" {
  api_key = var.cloudflare_api_key
  email   = var.cloudflare_email
}