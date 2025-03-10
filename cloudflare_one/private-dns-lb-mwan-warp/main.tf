module "random" {
  source = "./modules/random"

  for_each = var.magic-wan-rtr
}

# Generate a Pre-Shared Key for the IPSec Tunnel
resource "random_password" "ipsec_psk" {
  length = 16
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
  tunnel_secret = module.random[each.key].result

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

module "magic_wan_router" {
  source = "./modules/gcp_compute"

  for_each = var.magic-wan-rtr

  name_prefix  = var.gcp_label_owner
  name         = each.value.mwan-rtr-name
  zone         = each.value.zone
  machine_type = var.machine_type

  preemptible       = false
  automatic_restart = false

  labels = {
    owner  = var.gcp_label_owner,
    team   = var.gcp_label_team,
    region = var.gcp_label_region
  }

  tags  = ["${var.gcp_label_owner}-${var.gcp_network_tag}"]
  image = var.server_image

  network      = var.vpc
  subnetwork   = var.subnetwork
  network_tier = var.network_tier

  # Pass the template file and variables
  startup_script_template = each.value.mwan-rtr-linux-script
  template_vars = {
    account_id      = var.cloudflare_account_id
    api_key         = var.cloudflare_api_key
    email           = var.cloudflare_email
    psk             = random_password.ipsec_psk.result
    cf_endpoint     = var.cf_mwan_ip_1
    cf_int_addr     = each.value.tunnel_1.cf_int_addr
    tunnel_name     = each.value.tunnel_1.name
    vm_int_addr     = each.value.tunnel_1.vm_int_addr
    loopback_addr   = each.value.tunnel_1.loopback_addr
    cfd_tunnel_id   = module.ssh_dns[each.key].tunnel_id
    cfd_tunnel_name = each.value.ssh_tunnel_name
    cfd_secret      = module.random[each.key].result
    cfd_ssh_ca_cert = module.access_ssh[each.key].ssh_pub_key
    cfd_username    = var.gcp_username
    dns_record      = "${each.value.ssh_dns_record}.${var.domain_name}"
  }
}

# Create Magic WAN IPsec tunnels for each router
module "magic_wan" {
  source = "./modules/magic_wan"

  for_each = var.magic-wan-rtr

  # Cloudflare account details
  cloudflare_account_id = var.cloudflare_account_id

  # Tunnel configuration
  tunnel_name         = each.value.tunnel_1.name
  customer_endpoint   = module.magic_wan_router[each.key].public_ip
  cloudflare_endpoint = var.cf_mwan_ip_1
  interface_address   = each.value.tunnel_1.cf_int_addr
  description         = each.value.tunnel_1.description
  psk                 = random_password.ipsec_psk.result

  # Health check configuration
  health_check_enabled   = true
  health_check_type      = "request"
  health_check_direction = "bidirectional"

  # Static route configuration
  route_prefix   = each.value.tunnel_1.loopback_addr
  route_nexthop  = each.value.tunnel_1.cf_next_hop_ip
  route_priority = 100

  # Module dependencies
  depends_on = [module.magic_wan_router]
}