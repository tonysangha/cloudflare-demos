output "public_ip" {
  value = { for k, v in google_compute_instance.cloud_routers : k => v.network_interface.0.access_config[0].nat_ip }
}