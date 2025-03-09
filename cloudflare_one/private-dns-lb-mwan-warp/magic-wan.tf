module "random" {
  source = "./modules/random"

  for_each = var.magic-wan-rtr
}

module "ssh_dns" {
  source = "./modules/dns"

  for_each = var.magic-wan-rtr

  cloudflare_email      = var.cloudflare_email
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  cloudflare_api_key    = var.cloudflare_api_key

  tunnel_name   = each.key
  dns_record    = each.value.ssh_dns_record
  tunnel_secret = module.random[each.key].argo_id

  depends_on = [module.random]
}

module "access_ssh" {
  source = "./modules/access_ssh"

  for_each = var.magic-wan-rtr

  cloudflare_email      = var.cloudflare_email
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  cloudflare_api_key    = var.cloudflare_api_key

  ssh_app_name       = each.value.ssh_app_name
  dns_record         = each.value.ssh_dns_record
  service_type       = each.value.ssh_service_type
  session_duration   = each.value.ssh_session_duration
  access_policy_name = each.value.ssh_access_policy_name
  email_domain       = each.value.ssh_email_domain
  logo_url           = each.value.ssh_logo_url

  domain_name = var.domain_name

  depends_on = [module.ssh_dns]
}

# Generate a Pre-Shared Key for the IPSec Tunnel
resource "random_password" "ipsec_psk" {
  length = 16
}

# Create 1 or more Magic WAN Routers
resource "google_compute_instance" "magic-wan-rtr" {

  for_each = var.magic-wan-rtr

  name         = "${var.gcp_label_owner}-${each.value.mwan-rtr-name}"
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
      network_tier = var.network_tier
    }
  }

  metadata_startup_script = templatefile(each.value.mwan-rtr-linux-script,
    {
      account_id = var.cloudflare_account_id
      api_key    = var.cloudflare_api_key
      email      = var.cloudflare_email

      # Magic WAN IPSec configuration
      psk           = random_password.ipsec_psk.result,
      cf_endpoint   = var.cf_mwan_ip_1
      cf_int_addr   = each.value.tunnel_1.cf_int_addr
      tunnel_name   = each.value.tunnel_1.name
      vm_int_addr   = each.value.tunnel_1.vm_int_addr
      loopback_addr = each.value.tunnel_1.loopback_addr

      # Cloudflare Tunnel configuration
      cfd_tunnel_id   = module.ssh_dns[each.key].tunnel_id,
      cfd_tunnel_name = each.value.ssh_tunnel_name,
      cfd_secret      = module.random[each.key].argo_id
      cfd_ssh_ca_cert = module.access_ssh[each.key].ssh_pub_key
      cfd_username    = var.gcp_username

      dns_record = "${each.value.ssh_dns_record}.${var.domain_name}",
  })

  depends_on = [module.ssh_dns]
}

# https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/magic_wan_ipsec_tunnel
resource "cloudflare_magic_wan_ipsec_tunnel" "ipsec_rtr" {

  for_each = var.magic-wan-rtr

  account_id             = var.cloudflare_account_id
  name                   = each.value.tunnel_1.name
  customer_endpoint      = google_compute_instance.magic-wan-rtr[each.key].network_interface.0.access_config.0.nat_ip
  cloudflare_endpoint    = var.cf_mwan_ip_1
  interface_address      = each.value.tunnel_1.cf_int_addr
  description            = each.value.tunnel_1.description
  health_check_enabled   = true
  health_check_type      = "request"
  health_check_direction = "bidirectional"
  psk                    = random_password.ipsec_psk.result
  allow_null_cipher      = false
}

resource "cloudflare_magic_wan_static_route" "static_routes" {

  for_each = var.magic-wan-rtr

  account_id  = var.cloudflare_account_id
  description = each.value.tunnel_1.name
  prefix      = each.value.tunnel_1.loopback_addr
  nexthop     = each.value.tunnel_1.cf_next_hop_ip
  priority    = 100
  depends_on  = [cloudflare_magic_wan_ipsec_tunnel.ipsec_rtr]
}