output "ipsec_tunnel_ids" {
  value = {
    for k, v in cloudflare_ipsec_tunnel.ipsec_rtr : k => v.id
  }
}

output "instance_public_ip" {
  value = {
    for k, v in google_compute_instance.cloud-rtr : k => v.network_interface.0.access_config.0.nat_ip
  }
}
