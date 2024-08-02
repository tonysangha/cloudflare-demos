data "http" "cloudflare_ipv4_address" {
  url = "https://api.cloudflare.com/client/v4/ips"

  request_headers = {
    Accept = "application/json"
  }
}

resource "google_compute_firewall" "allow-ingress-ipsec-ah-in" {
  name      = "${var.gcp_label_owner}-${var.gcp_label_team}-${var.gcp_label_region}-allow-ingress-ipsec-ah-in"
  network   = var.vpc
  direction = "INGRESS"

  allow {
    protocol = "ah"
  }
  source_ranges = jsondecode(data.http.cloudflare_ipv4_address.response_body)["result"]["ipv4_cidrs"]
  priority      = "496"
  target_tags   = ["${var.gcp_label_owner}-${var.gcp_network_tag}"]
}

resource "google_compute_firewall" "allow-ingress-ipsec-esp-in" {
  name      = "${var.gcp_label_owner}-${var.gcp_label_team}-${var.gcp_label_region}-allow-ingress-ipsec-esp-in"
  network   = var.vpc
  direction = "INGRESS"

  allow {
    protocol = "esp"
  }
  source_ranges = jsondecode(data.http.cloudflare_ipv4_address.response_body)["result"]["ipv4_cidrs"]
  priority      = "497"
  target_tags   = ["${var.gcp_label_owner}-${var.gcp_network_tag}"]
}

resource "google_compute_firewall" "allow-ingress-ipsec-udp-in" {
  name      = "${var.gcp_label_owner}-${var.gcp_label_team}-${var.gcp_label_region}-allow-ingress-ipsec-udp-in"
  network   = var.vpc
  direction = "INGRESS"

  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }
  source_ranges = jsondecode(data.http.cloudflare_ipv4_address.response_body)["result"]["ipv4_cidrs"]
  priority      = "498"
  target_tags   = ["${var.gcp_label_owner}-${var.gcp_network_tag}"]
}

resource "google_compute_firewall" "allow-ingress-ssh-in" {
  name      = "${var.gcp_label_owner}-${var.gcp_label_team}-${var.gcp_label_region}-allow-ingress-ssh-in-all"
  network   = var.vpc
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = "499"
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
  priority      = "500"
  target_tags   = ["${var.gcp_label_owner}-${var.gcp_network_tag}"]
}
