# Create a VPC network
resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = true
  routing_mode            = var.routing_mode
}

# Create a single VPC Firewall rule (explicit deny) that blocks all connectivity inbound to the VPC
# Inbound firewall rules should be configured per application deployment

resource "google_compute_firewall" "deny-ingress-all" {
  name      = "${var.vpc_name}-deny-ingress-all"
  network   = var.vpc_name
  direction = "INGRESS"

  deny {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = "65534"
  depends_on    = [google_compute_network.vpc_network]
}
