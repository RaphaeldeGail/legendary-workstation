/**
 * # Service
 */

locals {
    host_network = [var.name, "host", "network"]
    route = ["route", "to", "destination", "ip"]
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