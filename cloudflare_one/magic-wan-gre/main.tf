# Create virtual machines in GCP

resource "google_compute_instance" "cloud_routers" {

  for_each = var.cloud_routers
  zone     = each.value.zone

  name         = "${var.gcp_label_owner}-${each.value.server_name}"
  machine_type = var.machine_type

  scheduling {
    preemptible       = false
    automatic_restart = false
  }

  labels = {
    owner  = var.gcp_label_owner
    team   = var.gcp_label_team
    region = var.gcp_label_region
  }
  metadata = {
    gre_lcl_cidr = each.value.gre_lcl_cidr
    gre_pub_cidr = each.value.gre_pub_cidr
    lo_cidr      = each.value.lo_cidr
    gre_next_hop = each.value.gre_next_hop
  }

  tags = ["${var.gcp_label_owner}-${var.gcp_network_tag}"]

  boot_disk {
    initialize_params {
      image = var.server_image
    }
  }

  network_interface {
    # Custom VPC and Subnetwork per instance created
    network    = var.vpc
    subnetwork = var.subnetwork

    access_config {
      nat_ip       = ""
      network_tier = var.network_tier
    }
  }


  metadata_startup_script = templatefile(var.script_loc,
    {
      lo_cidr      = each.value.lo_cidr
      cf_gre_ip_1  = var.cf_gre_ip_1
      gre_lcl_cidr = each.value.gre_lcl_cidr
      gre_next_hop = each.value.gre_next_hop
  })
}

# data resource to query google for VM information, for GRE tunnel resource

data "google_compute_instance" "cld_rtr" {

  for_each = var.cloud_routers

  name       = "${var.gcp_label_owner}-${each.value.server_name}"
  zone       = each.value.zone
  depends_on = [google_compute_instance.cloud_routers]
}

resource "cloudflare_magic_wan_gre_tunnel" "gre_tunnel" {

  account_id              = var.cloudflare_account_id
  for_each                = data.google_compute_instance.cld_rtr
  name                    = each.value.name # Tunnel name must be < 15 characters
  customer_gre_endpoint   = each.value.network_interface.0.access_config[0].nat_ip
  cloudflare_gre_endpoint = var.cf_gre_ip_1
  interface_address       = each.value.metadata.gre_pub_cidr
  description             = "${each.value.zone}-gre-tunnel"
  ttl                     = 64
  mtu                     = 1476
  health_check_enabled    = true
  depends_on              = [data.google_compute_instance.cld_rtr]
}

resource "cloudflare_magic_wan_static_route" "gre_static_routes" {

  account_id  = var.cloudflare_account_id
  for_each    = data.google_compute_instance.cld_rtr
  description = "${each.value.name}-loopback"
  prefix      = each.value.metadata.lo_cidr
  nexthop     = each.value.metadata.gre_next_hop
  priority    = 100
  weight      = 10

  depends_on = [cloudflare_magic_wan_gre_tunnel.gre_tunnel]
}