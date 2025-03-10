locals {
  # Build the instance name with optional prefix
  instance_name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name
  
  # Determine the startup script
  startup_script = var.startup_script != "" ? var.startup_script : (
    var.startup_script_template != "" ? templatefile(var.startup_script_template, var.template_vars) : ""
  )
  
  # Merge metadata with startup script if present
  metadata = local.startup_script != "" ? merge(var.metadata, {
    "startup-script" = local.startup_script
  }) : var.metadata
}

resource "google_compute_instance" "instance" {
  name         = local.instance_name
  zone         = var.zone
  machine_type = var.machine_type
  
  scheduling {
    preemptible       = var.preemptible
    automatic_restart = var.preemptible ? false : var.automatic_restart
  }
  
  # Labels and tags
  labels = var.labels
  tags   = var.tags
  
  # Boot disk configuration
  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = var.disk_type
    }
  }
  
  # Primary network interface
  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    
    # Only create access_config if NAT IP is required (public IP)
    dynamic "access_config" {
      for_each = var.network_tier != "" ? [1] : []
      content {
        nat_ip       = var.nat_ip
        network_tier = var.network_tier
      }
    }
  }
  
  # Add additional network interfaces if specified
  dynamic "network_interface" {
    for_each = var.additional_networks
    content {
      network    = network_interface.value["network"]
      subnetwork = lookup(network_interface.value, "subnetwork", null)
      
      dynamic "access_config" {
        for_each = lookup(network_interface.value, "access_config", false) ? [1] : []
        content {
          nat_ip       = lookup(network_interface.value, "nat_ip", null)
          network_tier = lookup(network_interface.value, "network_tier", "STANDARD")
        }
      }
    }
  }
  
  # Metadata including startup script
  metadata = local.metadata
  
  # Service account configuration
  dynamic "service_account" {
    for_each = var.service_account_email != "" ? [1] : []
    content {
      email  = var.service_account_email
      scopes = var.service_account_scopes
    }
  }
}