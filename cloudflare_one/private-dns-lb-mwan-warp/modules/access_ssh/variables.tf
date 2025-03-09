# Cloudflare Variables

variable "cloudflare_zone_id" {
  description = "The Cloudflare UUID for the Zone to use."
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
  description = "Cloudflare API Key"
  type        = string
  sensitive   = true
}
# variable "cloudflare_api_token" {
#   description = "Cloudflare API Token"
#   type        = string
#   sensitive   = true
# }
variable "ssh_app_name" {
  type    = string
  default = ""
}
variable "service_type" {
  type    = string
  default = ""
}
variable "session_duration" {
  type    = string
  default = "1h"
}
variable "access_policy_name" {
  type    = string
  default = ""
}

variable "email_domain" {
  type    = string
  default = ""
}

variable "logo_url" {
  type    = string
  default = ""
}

variable "dns_record" {
  type    = string
    default = ""
}

variable "domain_name" {
  description = "Domain Name"
  type        = string
}