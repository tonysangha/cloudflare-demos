# Create a application in Cloudflare Teams that will be used to authenticate to
resource "cloudflare_zero_trust_access_application" "ssh_application" {
  zone_id                   = var.cloudflare_zone_id
  name                      = var.ssh_app_name
  domain                    = "${var.dns_record}.${var.domain_name}"
  type                      = var.service_type
  session_duration          = var.session_duration
  logo_url                  = var.logo_url
  auto_redirect_to_identity = true
}

# Cloudflare Team's policy for application created prior
resource "cloudflare_zero_trust_access_policy" "access_policy" {
  application_id = cloudflare_zero_trust_access_application.ssh_application.id
  zone_id        = var.cloudflare_zone_id
  name           = var.access_policy_name
  precedence     = "10"
  decision       = "allow"

  include {
    email_domain = [var.email_domain]
  }

  require {
    email_domain = [var.email_domain]
  }
}

# Create SSH short-lived certificate
resource "cloudflare_zero_trust_access_short_lived_certificate" "ssh_short_lived" {
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_zero_trust_access_application.ssh_application.id
}