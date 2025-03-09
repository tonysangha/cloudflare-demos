output "preemptible_warning" {
  value = "Warning! GCP instances are preemptible and will be automatically destroyed after 24 hours!"
}

output "build_time" {
  value = formatdate("YYYY MMMM DD - hh:mm:ss ZZZ", timestamp())
}

output "ipsec_tunnel_ids" {
  value = {
    for k, v in cloudflare_magic_wan_ipsec_tunnel.ipsec_rtr : k => v.id
  }
}

output "instance_public_ip" {
  value = {
    for k, v in google_compute_instance.magic-wan-rtr : k => v.network_interface.0.access_config.0.nat_ip
  }
}
