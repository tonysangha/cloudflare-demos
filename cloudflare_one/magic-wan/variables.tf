# Variables for Provider Level Settings

variable "gcp_project" {
  description = "GCP Project ID"
  type        = string
  sensitive   = true
}

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
  description = "Cloudflare API key"
  type        = string
  sensitive   = true
}

# Google VM variables

variable "gcp_label_owner" {
  description = "label of the user who owns this deployment `username`"
  type        = string
}

variable "gcp_label_team" {
  description = "label of the team running this resource"
  type        = string
}
variable "gcp_network_tag" {
  description = "GCP Network Tag used for VPC Firewall Rules"
  type        = string
}

variable "machine_type" {
  description = "GCP instance type"
  type        = string
  default     = "e2-micro"
}

variable "server_image" {
  description = "Server OS Image to use"
  type        = string
  default     = "debian-12"
}

variable "network_type" {
  description = "Define which GCP std or prem networking to use"
  type        = string
  default     = "STANDARD"
}

variable "vpc" {
  description = "Virtual Private Cloud Network"
  type        = string
  default     = "default"
}

variable "linux_script" {
  description = "Configuration Script for Linux VMs in GCP"
  type        = string
}

variable "vms" {
  description = "MAP of VMs configuration"
  type        = map(any)
  default     = {}
}