output "tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.auto_tunnel.id
}

output "cnames" {
  value = ["${cloudflare_record.cname.*.name}"]
}