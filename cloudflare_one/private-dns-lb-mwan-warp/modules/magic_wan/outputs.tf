output "tunnel_id" {
  description = "ID of the created IPsec tunnel"
  value       = cloudflare_magic_wan_ipsec_tunnel.ipsec_tunnel.id
}

output "static_route_id" {
  description = "ID of the created static route"
  value       = cloudflare_magic_wan_static_route.static_route.id
}