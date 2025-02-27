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

  validation {
    condition     = length(var.gcp_project) > 4 && length(var.gcp_project) < 30
    error_message = "The GCP project ID must be between 5 and 29 characters."
  }
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

  validation {
    condition     = can(regex("^[a-z][0-9]-[a-z]+$", var.machine_type))
    error_message = "The machine_type must be a valid GCP machine type format (e.g., 'e2-micro')."
  }
}

variable "server_image" {
  description = "Server Image for use in GCP"
  type        = string
}

variable "network_tier" {
  description = "Standard or Premium Network Type"
  type        = string

  validation {
    condition     = contains(["STANDARD", "PREMIUM"], var.network_tier)
    error_message = "The network_tier must be either 'STANDARD' or 'PREMIUM'."
  }
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
  type = map(object({
    server_name  = string
    zone         = string
    lo_cidr      = string
    gre_lcl_cidr = string
    gre_next_hop = string
    gre_pub_cidr = string
  }))

  validation {
    condition = alltrue([
      for router in var.cloud_routers :
      can(regex("^[a-z]+-[a-z0-9]+-[a-z]$", router.zone))
    ])
    error_message = "All router zones must be in a valid GCP zone format (e.g., 'australia-southeast1-a')."
  }

  validation {
    condition = alltrue([
      for router in var.cloud_routers :
      can(cidrnetmask(router.lo_cidr))
    ])
    error_message = "All loopback CIDR blocks must be valid."
  }
}

variable "cf_gre_ip_1" {
  description = "Cloudflare GRE Tunnel IP Address"
  type        = string
  default     = ""

  validation {
    condition     = can(cidrnetmask("${var.cf_gre_ip_1}/32"))
    error_message = "The cf_gre_ip_1 value must be a valid IP address"
  }
}

variable "cf_gre_ip_2" {
  description = "Cloudflare GRE Tunnel IP Address"
  type        = string
  default     = ""

  validation {
    condition     = can(cidrnetmask("${var.cf_gre_ip_2}/32"))
    error_message = "The cf_gre_ip_2 value must be a valid IP address"
  }
}