# Cloudflare Variables

variable "cloudflare_zone_id" {
  description   = "The Cloudflare UUID for the Zone to use."
  type          = string
  sensitive     = true
}

variable "cloudflare_account_id" {
  description   = "The Cloudflare UUID for the Account the Zone lives in."
  type          = string
  sensitive     = true
}

variable "cloudflare_email" {
  description   = "The Cloudflare user."
  type          = string
  sensitive     = true
}

variable "cloudflare_api_key" {
  description   = "Cloudflare API Key"
  type          = string
  sensitive     = true
}
variable "tunnel_secret" {
  description   = "32 digit secret"
  type          = string
  sensitive     = true
}

variable "tunnel_name" {
  description   = "ARGO Tunnel Name"
  type          = string
}

variable "dns_record" {
    type        = string
}
