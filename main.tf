/**
 * # Legendary Workstation
 * 
 * This code sets up a plateform for managing a development environment in Google Cloud.
 * 
 * Along with a development server, securized networking access are provided.
 */

terraform {
  required_version = "~> 1.1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.5.0"
    }
  }
  backend "gcs" {
    prefix = "terraform/state"
  }
}

provider "google" {
  region  = var.region
  project = var.project_id
}

resource "google_compute_network" "network" {
  name                            = var.core.network.name
  description                     = title(join(" ", [var.core.network.name, "core network"]))
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "subnetwork" {
  name        = join("-", ["workspace", var.core.network.name])
  description = title("workspace subnet in ${var.core.network.name} network")
  network     = google_compute_network.network.id

  ip_cidr_range = cidrsubnet(var.core.network.base_cidr_block, 2, 0)
}

resource "google_compute_route" "default_route" {
  name        = join("-", ["from", var.core.network.name, "to", "internet"])
  description = title(join(" ", ["from", var.core.network.name, "to", "internet"]))
  network     = google_compute_network.network.name

  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  tags             = ["workspace"]
}

resource "google_compute_router" "nat_router" {
  name        = join("-", [var.core.network.name, "router"])
  description = title(join("-", [var.core.network.name, "router"]))
  network     = google_compute_network.network.id
}

resource "google_compute_router_nat" "nat_gateway" {
  name                               = join("-", [var.core.network.name, "nat", "gateway"])
  router                             = google_compute_router.nat_router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}