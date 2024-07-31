data "http" "cloudflare_ipv4_address" {
  url = "https://api.cloudflare.com/client/v4/ips"

  request_headers = {
    Accept = "application/json"
  }
}

resource "google_compute_firewall" "allow-cloudflare-gre-out" {
  name        = "${var.gcp_label_owner}-${var.gcp_label_team}-${var.gcp_label_region}-allow-gre-egress-to-cloudflare-ips"
  description = "Allow GRE outbound to Cloudflare IPv4 addresses"
  network     = var.vpc
  direction   = "EGRESS"

  allow {
    protocol = "47"
  }
  destination_ranges = jsondecode(data.http.cloudflare_ipv4_address.response_body)["result"]["ipv4_cidrs"]
  priority           = "451"
  target_tags        = ["${var.gcp_label_owner}-${var.gcp_network_tag}"]
}

resource "google_compute_firewall" "allow-cloudflare-gre-in" {
  name        = "${var.gcp_label_owner}-${var.gcp_label_team}-${var.gcp_label_region}-allow-gre-ingress-from-cloudflare-ips"
  description = "Allow GRE inbound from Cloudflare IPv4 addresses"
  network     = var.vpc
  direction   = "INGRESS"

  allow {
    protocol = "47"
  }
  source_ranges = jsondecode(data.http.cloudflare_ipv4_address.response_body)["result"]["ipv4_cidrs"]
  priority      = "452"
  target_tags   = ["${var.gcp_label_owner}-${var.gcp_network_tag}"]
}

resource "google_compute_firewall" "allow-ssh-in" {
  name      = "${var.gcp_label_owner}-${var.gcp_label_team}-${var.gcp_label_region}-allow-ssh-in-all"
  network   = var.vpc
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = "453"
  target_tags   = ["${var.gcp_label_owner}-${var.gcp_network_tag}"]
}

resource "google_compute_firewall" "deny-ingress-all" {
  name      = "${var.gcp_label_owner}-${var.gcp_label_team}-${var.gcp_label_region}-deny-ingress-all"
  network   = var.vpc
  direction = "INGRESS"

  deny {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = "455"
  target_tags   = ["${var.gcp_label_owner}-${var.gcp_network_tag}"]
}