################################
### Provider Level Variables ###
################################

variable "gcp_project" {
  description = "GCP Project ID"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.gcp_project) > 4 && length(var.gcp_project) < 30
    error_message = "The GCP project ID must be between 5 and 29 characters."
  }
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

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for public DNS records"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain Name"
  type        = string
}

################################
### GCP Labels and Tags      ###
################################

variable "gcp_label_owner" {
  description = "Label of the user who owns this deployment `username`"
  type        = string
}

variable "gcp_label_team" {
  description = "Label of the team running this resource"
  type        = string
}
variable "gcp_network_tag" {
  description = "GCP Network Tag used for VPC Firewall Rules"
  type        = string
}

variable "gcp_label_region" {
  description = "Region label to help identify which region is the owner"
  type        = string
}

variable "gcp_username" {
  description = "Username of primary GCP VM"
  type        = string
}

################################
### Cloudflare Magic WAN     ###
################################

variable "cf_mwan_ip_1" {
  description = "Cloudflare Magic WAN Tunnel IP Address"
  type        = string
  default     = ""

  validation {
    condition     = can(cidrnetmask("${var.cf_mwan_ip_1}/32"))
    error_message = "The cf_mwan_ip_1 value must be a valid IP address"
  }
}

# variable "cf_mwan_ip_2" {
#   description = "Cloudflare mwan Tunnel IP Address"
#   type        = string
#   default     = ""

#   validation {
#     condition     = can(cidrnetmask("${var.cf_mwan_ip_2}/32"))
#     error_message = "The cf_mwan_ip_2 value must be a valid IP address"
#   }
# }

################################
### GCP Magic WAN Config     ###
################################

# TODO: Specify map types
variable "magic-wan-rtr" {
  description = "Magic WAN Router'(s) configuration"
  type        = map(any)
  default     = {}
}

################################
### GCP Demo Wide Config     ###
################################

variable "machine_type" {
  description = "Machine Type for use in GCP"
  type        = string
  default     = "e2-micro"

  validation {
    condition     = can(regex("^[a-z][0-9]-[a-z]+$", var.machine_type))
    error_message = "The machine_type must be a valid GCP machine type format (e.g., 'e2-micro')."
  }
}

variable "server_image" {
  description = "Server OS Image to use"
  type        = string
}

variable "network_tier" {
  description = "Standard or Premium Network Type"
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "PREMIUM"], var.network_tier)
    error_message = "The network_tier must be either 'STANDARD' or 'PREMIUM'."
  }
}

variable "vpc" {
  description = "Virtual Private Cloud Network"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork to use when VPC is custom mode"
  type        = string
}




