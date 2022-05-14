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

module "ssh_service" {
  source = "./modules/service"

  name           = "ssh"
  full_version   = "1.0.0"
  destination_ip = "86.70.78.151/32"
  port           = 22

  index = 1

  back_network = {
    name            = var.core.network.name
    base_cidr_block = var.core.network.base_cidr_block
    id              = google_compute_network.network.id
  }
  metadata = {
    user-data              = trimspace(templatefile("./cloud-config.tpl", { rsa_private = var.rsa_key, rsa_public = var.rsa_pub, ssh_public = var.ssh_pub }))
    startup-script         = trimspace(templatefile("./startup-script.tpl", { local_ip = "86.70.78.151/32" }))
    block-project-ssh-keys = true
  }
}

module "http_service" {
  source = "./modules/service"

  name           = "http"
  full_version   = "1.0.0"
  destination_ip = "86.70.78.151/32"
  port           = 443

  index = 2

  back_network = {
    name            = var.core.network.name
    base_cidr_block = var.core.network.base_cidr_block
    id              = google_compute_network.network.id
  }
  metadata = {
    user-data              = trimspace(templatefile("./cloud-config.tpl", { rsa_private = var.rsa_key, rsa_public = var.rsa_pub, ssh_public = var.ssh_pub }))
    startup-script         = trimspace(templatefile("./startup-script.tpl", { local_ip = "86.70.78.151/32" }))
    block-project-ssh-keys = true
  }
}

resource "google_compute_disk" "data_disk" {
  name                      = "data-disk"
  description               = "Data Disk"
  size                      = 10
  type                      = "pd-standard"
  physical_block_size_bytes = 4096
  zone                      = "europe-west1-b"
}

resource "google_compute_instance" "workstation" {
  name        = "workstation"
  description = title("Workstation instance")
  zone        = "europe-west1-b"

  tags           = ["workspace"]
  machine_type   = "e2-small"
  can_ip_forward = false

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-lts"
      size  = 10
    }
    auto_delete = true
  }

  attached_disk {
    source      = google_compute_disk.data_disk.id
    device_name = "data-disk"
    mode        = "READ_WRITE"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.id
  }

  metadata = {
    block-project-ssh-keys = true
    ssh-keys               = join(":", ["raphael", trimspace(var.ssh_pub)])
  }

}