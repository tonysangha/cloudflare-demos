output "preemptible_warning" {
  value = "Warning! GCP instances are preemptible and will be automatically destroyed after 24 hours!"
}

output "build_time" {
  value = formatdate("YYYY MMMM DD - hh:mm:ss ZZZ", timestamp())
}


output "ipsec_tunnel_ids" {
  value = {
    for k, v in module.magic_wan : k => v.tunnel_id
  }
}

output "instance_public_ip" {
  value = {
    for k, v in module.magic_wan_router : k => v.public_ip
  }
}