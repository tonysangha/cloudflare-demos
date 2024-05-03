resource "google_compute_instance" "vm_instance" {

  for_each = var.vms


  name         = "${var.gcp_label_owner}-${var.gcp_label_team}-${each.value.server_name}"
  zone         = each.value.zone
  machine_type = var.machine_type

  // Preemptible resources are terminated after 24 hrs and no guarantee of resources
  // https://cloud.google.com/compute/docs/instances/preemptible

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  labels = {
    owner = var.gcp_label_owner,
    team  = var.gcp_label_team
  }
  tags = [var.gcp_network_tag]

  boot_disk {
    initialize_params {
      image = var.server_image
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network    = var.vpc
    subnetwork = each.value.subnetwork
    access_config {
      nat_ip       = ""
      network_tier = var.network_type
    }
  }

  metadata_startup_script = templatefile(var.linux_script,
    {
      account_id      = var.cloudflare_account_id
      api_key         = var.cloudflare_api_key
      email           = var.cloudflare_email
      psk             = random_password.ipsec_psk.result,
      cf_endpoint     = each.value.tunnel_1.cf_endpoint
      tunnel_name     = each.value.tunnel_1.name
      health_check_ip = each.value.tunnel_1.health_check_ip
      loopback_addr   = each.value.tunnel_1.loopback_addr
  })

}
