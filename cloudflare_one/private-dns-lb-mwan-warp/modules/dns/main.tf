# A Named Tunnel resource
resource "cloudflare_zero_trust_tunnel_cloudflared" "auto_tunnel" {
  account_id = var.cloudflare_account_id
  name       = var.tunnel_name
  secret     = var.tunnel_secret
}

# Create CNAME records with the ARGO tunnel as the the record
resource "cloudflare_record" "cname" {
  zone_id = var.cloudflare_zone_id
  name    = var.dns_record
  content   = "${cloudflare_zero_trust_tunnel_cloudflared.auto_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}