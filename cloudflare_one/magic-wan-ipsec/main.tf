resource "random_password" "ipsec_psk" {
  length = 16
}

resource "google_compute_instance" "cloud-rtr" {

  for_each = var.cloud-rtrs

  name         = "${var.gcp_label_owner}-${each.value.server_name}"
  zone         = each.value.zone
  machine_type = var.machine_type

  // Preemptible resources are terminated after 24 hrs and no guarantee of resources
  // https://cloud.google.com/compute/docs/instances/preemptible

  scheduling {
    preemptible       = false
    automatic_restart = false
  }

  labels = {
    owner  = var.gcp_label_owner,
    team   = var.gcp_label_team
    region = var.gcp_label_region

  }
  tags = ["${var.gcp_label_owner}-${var.gcp_network_tag}"]

  boot_disk {
    initialize_params {
      image = var.server_image
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network    = var.vpc
    subnetwork = var.subnetwork
    access_config {
      nat_ip       = ""
      network_tier = var.network_type
    }
  }

  metadata_startup_script = templatefile(var.linux_script,
    {
      account_id    = var.cloudflare_account_id
      api_key       = var.cloudflare_api_key
      email         = var.cloudflare_email
      psk           = random_password.ipsec_psk.result,
      cf_endpoint   = var.cf_gre_ip_1
      cf_int_addr   = each.value.tunnel_1.cf_int_addr
      tunnel_name   = each.value.tunnel_1.name
      vm_int_addr   = each.value.tunnel_1.vm_int_addr
      loopback_addr = each.value.tunnel_1.loopback_addr
  })

}

# https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ipsec_tunnel
resource "cloudflare_ipsec_tunnel" "ipsec_rtr" {

  for_each = var.cloud-rtrs

  account_id             = var.cloudflare_account_id
  name                   = each.value.tunnel_1.name
  customer_endpoint      = google_compute_instance.cloud-rtr[each.key].network_interface.0.access_config.0.nat_ip
  cloudflare_endpoint    = var.cf_gre_ip_1
  interface_address      = each.value.tunnel_1.cf_int_addr
  description            = each.value.tunnel_1.description
  health_check_enabled   = true
  health_check_type      = "request"
  health_check_direction = "bidirectional"
  psk                    = random_password.ipsec_psk.result
  allow_null_cipher      = false
  depends_on             = [google_compute_instance.cloud-rtr]
}

resource "cloudflare_static_route" "static_routes" {

  for_each = var.cloud-rtrs

  account_id  = var.cloudflare_account_id
  description = each.value.tunnel_1.name
  prefix      = each.value.tunnel_1.loopback_addr
  nexthop     = each.value.tunnel_1.cf_next_hop_ip
  priority    = 100
  depends_on  = [cloudflare_ipsec_tunnel.ipsec_rtr]
}