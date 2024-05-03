output "preemptible_warning" {
  value = "Warning! These instances are preemptible and will be automatically destroyed after 24 hours!"
}

output "ipsec_tunnel_ids" {
  value = {
    for k, v in cloudflare_ipsec_tunnel.ipsec_rtr : k => v.id
  }
}

output "instanace_public_ip" {
  value = {
    for k, v in google_compute_instance.vm_instance : k => v.network_interface.0.access_config.0.nat_ip
  }
}
