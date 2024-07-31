variable "cloudflare_account_id" {
  description = "The Cloudflare UUID for the Account the Zone lives in."
  type        = string
  sensitive   = true
}

variable "cloudflare_email" {
  description = "The Cloudflare user."
  type        = string
  sensitive   = true
}

variable "cloudflare_api_key" {
  description = "Cloudflare API Key"
  type        = string
  sensitive   = true
}

variable "gcp_project" {
  description = "GCP Project ID"
  type        = string
  sensitive   = true
}

variable "gcp_label_owner" {
  description = "Label the owner of a GCP object:"
  type        = string
}

variable "gcp_label_team" {
  description = "Network label used for FW rules"
  type        = string
}

variable "gcp_label_region" {
  description = "Region label to help identify which region is the owner"
  type        = string
}

variable "gcp_network_tag" {
  description = "Network Tag used to scope VPC Firewall Rule"
  type        = string
}

variable "machine_type" {
  description = "Machine Type for use in GCP"
  type        = string
}

variable "server_image" {
  description = "Server Image for use in GCP"
  type        = string
}

variable "network_tier" {
  description = "Standard or Premium Network Type"
  type        = string
}

variable "script_loc" {
  description = "Script file location relative to execution directory"
  type        = string
}

variable "vpc" {
  description = "Virtual Private Cloud network to put VMs onto"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork to use when VPC is custom mode"
  type        = string
}

variable "cloud_routers" {
  description = "Map of Cloud Routers"
  type        = map(any)
  default     = {}
}

variable "cf_gre_ip_1" {
  description = "Cloudflare GRE Tunnel IP Address"
  type        = string
  default     = ""
}

variable "cf_gre_ip_2" {
  description = "Cloudflare GRE Tunnel IP Address"
  type        = string
  default     = ""
}