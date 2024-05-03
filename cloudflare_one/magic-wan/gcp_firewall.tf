data "http" "cloudflare_ipv4_address" {
  url = "https://api.cloudflare.com/client/v4/ips"

  request_headers = {
    Accept = "application/json"
  }
}

resource "google_compute_firewall" "allow-cloudflare-ips-in" {
  name        = "${var.gcp_label_owner}-${var.gcp_label_team}-cf-ipv4-allow-in"
  description = "Allow Cloudflare IPv4 addresses inbound"
  network     = var.vpc

  allow {
    protocol = "all"
  }
  source_ranges = jsondecode(data.http.cloudflare_ipv4_address.response_body)["result"]["ipv4_cidrs"]
  priority      = "498"
  target_tags   = [var.gcp_network_tag]
}

resource "google_compute_firewall" "allow-ssh-in" {
  name    = "${var.gcp_label_owner}-${var.gcp_label_team}-allow-ssh-in"
  network = var.vpc

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = "499"
  target_tags   = [var.gcp_network_tag]
}

resource "google_compute_firewall" "block-ingress-all" {
  name    = "${var.gcp_label_owner}-${var.gcp_label_team}-block-ingress-all"
  network = var.vpc

  deny {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = "500"
  target_tags   = [var.gcp_network_tag]
}