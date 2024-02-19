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

}
