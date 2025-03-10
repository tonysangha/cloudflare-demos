resource "cloudflare_magic_wan_ipsec_tunnel" "ipsec_tunnel" {

  account_id             = var.cloudflare_account_id
  name                   = var.tunnel_name
  description            = var.description
  customer_endpoint      = var.customer_endpoint
  cloudflare_endpoint    = var.cloudflare_endpoint
  interface_address      = var.interface_address
  health_check_enabled   = var.health_check_enabled
  health_check_type      = var.health_check_type
  health_check_direction = var.health_check_direction
  psk                    = var.psk
  allow_null_cipher      = var.allow_null_cipher
}

resource "cloudflare_magic_wan_static_route" "static_route" {

  account_id  = var.cloudflare_account_id
  description = var.description
  prefix      = var.route_prefix
  nexthop     = var.route_nexthop
  priority    = var.route_priority
  depends_on  = [cloudflare_magic_wan_ipsec_tunnel.ipsec_tunnel]
}