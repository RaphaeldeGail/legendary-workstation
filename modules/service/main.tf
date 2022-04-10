/**
 * # Service
 */

locals {
    host_network = [var.name, "host", "network"]
    route = ["route", "to", "destination", "ip"]
}

data "google_netblock_ip_ranges" "legacy-hcs" {
  range_type = "legacy-health-checkers"
}

resource "google_compute_network" "host_network" {
  name                            = join("-", local.host_network)
  description                     = title(join(" ", local.host_network))
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "host_subnetwork" {
  name          = join("-", ["main","subnet"])
  description   = title(join(" ", concat(["main", "subnet", "in"], local.host_network)))
  network       = google_compute_network.host_network.id

  ip_cidr_range = cidrsubnet("172.16.0.0/12", 10, 0)
}

resource "google_compute_route" "route" {
  name             = join("-", local.route)
  description      = title(join(" ",concat(local.route, [var.destination_ip])))
  network          = google_compute_network.host_network.name

  dest_range       = var.destination_ip
  next_hop_gateway = "default-internet-gateway"
  priority         = 10
  tags             = [var.name]
}

resource "google_compute_subnetwork" "base_subnetwork" {
  name          = join("-", [var.name, "subnet"])
  description   = title("${var.name} subnet in ${var.name} network")
  network       = var.base_network.id

  ip_cidr_range = cidrsubnet(var.base_network.base_cidr_block, 2, 1)
}

resource "google_compute_firewall" "to_host" {
  name        = join("-", ["allow", "from", "destination", "to", var.name, "tcp", tostring(var.port)])
  description = title("Allow connection from dedicated network to ${var.name} servers")
  network     = google_compute_network.host_network.id
  direction   = "INGRESS"
  priority    = 10

  allow {
    protocol = "tcp"
    ports    = [tostring(var.port)]
  }

  source_ranges = [var.destination_ip]
  target_tags   = [var.name]
}

resource "google_compute_firewall" "from_base" {
  name        = join("-", ["allow", "from", var.name, "to", "workspace", "tcp", tostring(var.port)])
  description = "Allow connection from ${var.name} servers to workspace"
  network     = var.base_network.id
  direction   = "INGRESS"
  priority    = 10

  allow {
    protocol = "tcp"
    ports    = [tostring(var.port)]
  }

  source_tags = [var.name]
  target_tags = ["workspace"]
}

resource "google_compute_firewall" "healthcheck" {
  name        = "allow-from-healthcheck-to-bounce-tcp-80"
  description = "Allow HTTP connection from Google health checks to bounce servers"
  network     = google_compute_network.host_network.id
  direction   = "INGRESS"
  priority    = 100

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = data.google_netblock_ip_ranges.legacy-hcs.cidr_blocks_ipv4
  target_tags   = [var.name]
}
