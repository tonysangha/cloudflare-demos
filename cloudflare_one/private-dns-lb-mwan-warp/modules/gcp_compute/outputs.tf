output "id" {
  description = "The instance ID"
  value       = google_compute_instance.instance.id
}

output "name" {
  description = "The instance name"
  value       = google_compute_instance.instance.name
}

output "self_link" {
  description = "The URI of the instance"
  value       = google_compute_instance.instance.self_link
}

output "public_ip" {
  description = "The public IP address of the instance"
  value       = length(google_compute_instance.instance.network_interface) > 0 && length(google_compute_instance.instance.network_interface[0].access_config) > 0 ? google_compute_instance.instance.network_interface[0].access_config[0].nat_ip : null
}

output "private_ip" {
  description = "The private IP address of the instance"
  value       = length(google_compute_instance.instance.network_interface) > 0 ? google_compute_instance.instance.network_interface[0].network_ip : null
}

output "instance" {
  description = "The entire instance resource"
  value       = google_compute_instance.instance
}