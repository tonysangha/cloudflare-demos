# Cloudflare authentication and account variables
variable "cloudflare_account_id" {
  description = "The Cloudflare UUID for the Account"
  type        = string
  sensitive   = true
}

# IPsec tunnel configuration variables
variable "tunnel_name" {
  description = "Name of the IPsec tunnel"
  type        = string
}

variable "customer_endpoint" {
  description = "Public IP address of the customer endpoint (router public IP)"
  type        = string
}

variable "cloudflare_endpoint" {
  description = "Cloudflare Anycast IP address"
  type        = string
}

variable "interface_address" {
  description = "Interface address for the tunnel on Cloudflare side (CIDR format)"
  type        = string
}

variable "description" {
  description = "Description of the IPsec tunnel"
  type        = string
  default     = ""
}

# IPsec tunnel health check variables
variable "health_check_enabled" {
  description = "Enable health checks for the tunnel"
  type        = bool
  default     = true
}

variable "health_check_type" {
  description = "Type of health check for the tunnel (request, reply)"
  type        = string
  default     = "request"
  
  validation {
    condition     = contains(["request", "reply"], var.health_check_type)
    error_message = "The health_check_type must be either 'request' or 'reply'."
  }
}

variable "health_check_direction" {
  description = "Direction for health check traffic (unidirectional, bidirectional)"
  type        = string
  default     = "bidirectional"
  
  validation {
    condition     = contains(["unidirectional", "bidirectional"], var.health_check_direction)
    error_message = "The health_check_direction must be either 'unidirectional' or 'bidirectional'."
  }
}

# IPsec security variables
variable "psk" {
  description = "Pre-shared key for the IPsec tunnel authentication"
  type        = string
  sensitive   = true
}

variable "allow_null_cipher" {
  description = "Allow null cipher for the IPsec tunnel (not recommended for production)"
  type        = bool
  default     = false
}

# Static route variables
variable "route_prefix" {
  description = "CIDR prefix for the static route (e.g., '192.168.1.0/24')"
  type        = string
  
  validation {
    condition     = can(cidrnetmask(var.route_prefix))
    error_message = "The route_prefix must be a valid CIDR notation."
  }
}

variable "route_nexthop" {
  description = "Next hop IP address for the static route"
  type        = string
  
  validation {
    condition     = can(cidrnetmask("${var.route_nexthop}/32"))
    error_message = "The route_nexthop must be a valid IP address."
  }
}

variable "route_priority" {
  description = "Priority for the static route (lower values have higher priority)"
  type        = number
  default     = 100
  
  validation {
    condition     = var.route_priority >= 1 && var.route_priority <= 1000
    error_message = "The route_priority must be between 1 and 1000."
  }
}

variable "route_description" {
  description = "Description of the static route"
  type        = string
  default     = ""
}
