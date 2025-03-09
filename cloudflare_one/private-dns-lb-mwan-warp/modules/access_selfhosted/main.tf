# Create a application in Cloudflare Teams that will be used to authenticate to
resource "cloudflare_access_application" "self-hosted-app" {
  zone_id                   = var.cloudflare_zone_id
  name                      = var.app_name
  domain                    = "${var.dns_records[0].cname}.${var.domain_name}"
  type                      = var.service_type
  session_duration          = var.session_duration
  logo_url                  = var.logo_url
  auto_redirect_to_identity = true
}

# Cloudflare Team's policy for application created prior
resource "cloudflare_access_policy" "access_policy" {
  application_id = cloudflare_access_application.self-hosted-app.id
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