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
  description = "Cloudflare Zone"
  type = string
  sensitive = false
}

variable "rule_name" {
  description = "Rule Name"
  type = string
  sensitive = false
}

variable "rule_desc" {
  description = "Rule Description"
  type = string
  sensitive = false
}

