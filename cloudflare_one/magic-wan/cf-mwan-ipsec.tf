# https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ipsec_tunnel
resource "cloudflare_ipsec_tunnel" "ipsec_rtr" {
  for_each = var.vms

  account_id           = var.cloudflare_account_id
  name                 = each.value.tunnel_1.name
  customer_endpoint    = google_compute_instance.vm_instance[each.key].network_interface.0.access_config.0.nat_ip
  cloudflare_endpoint  = each.value.tunnel_1.cf_endpoint
  interface_address    = each.value.tunnel_1.int_address
  description          = each.value.tunnel_1.description
  health_check_enabled = true
  health_check_target  = each.value.tunnel_1.health_check_ip
  health_check_type    = "reply"
  psk                  = random_password.ipsec_psk.result
  allow_null_cipher    = false
  depends_on           = [google_compute_instance.vm_instance]
}