/**
 * # Legendary Workstation
 * 
 * This code sets up a plateform for managing a development environment in Google Cloud, similar to a local environment (local virtual machine).
 * 
 * ## Infrastructure description
 *
 * The code creates a private Google network, hosting a workload instance for development purpose.
 *
 * The instance is bound to a supplementary data disk with a backup strategy in order to prevent user data loss.
 *
 * The instance also has access to a dedicated bucket for ease of storing.
 *
 * The private Google network has access to the internet via a NAT gateway with dynamic output IP addresses.
 *
 * The platform also has dedicated access for SSH and HTTP services through group of gateways routed to a single IP address.
 *
 * The gateways are exposed behind Layer 4 loadbalancers.
 *
 * ## Usage
 *
 * Before building the platform, you should build your own image for SSH and HTTP gateways with packer.
 *
 * Please refer to the documentation in the following repositories:
 * [SSH](https://github.com/RaphaeldeGail/redesigned-bounce-image) and
 * [HTTP](https://github.com/RaphaeldeGail/vigilant-envoy-image)
 *
 * Set the values of the required variables in terraform.tfvars and set the name of the images you built with packer in the main code.
 *
 * Authenticate to Google Cloud Platform with a relevant account or set the environment variable *GOOGLE_APPLICATION_CREDENTIALS* to the path of a JSON service account key.
 *
 * Simply run:
 *
 * ```bash
 * terraform init
 * terraform apply
 * ```
 *
 */

terraform {
  required_version = "~> 1.1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.5.0"
    }
  }
  backend "gcs" {
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.workspace.project
  region  = var.workspace.region
}

locals {
  // Default IP address range for the worksapce network
  base_cidr_block = "10.1.0.0/27"
}

resource "google_compute_network" "network" {
  name        = join("-", [var.workspace.name, "network"])
  description = "Main network for the workspace"

  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "subnetwork" {
  name        = join("-", ["workstations", "subnet"])
  description = "Subnetwork hosting workstation instances"

  network       = google_compute_network.network.id
  ip_cidr_range = cidrsubnet(local.base_cidr_block, 2, 0)
}

resource "google_compute_route" "default_route" {
  name        = join("-", ["from", var.workspace.name, "to", "internet"])
  description = "Default route from the workspace network to the internet"

  network          = google_compute_network.network.name
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  tags             = [var.workspace.name]
}

resource "google_compute_router" "default_router" {
  name        = join("-", [var.workspace.name, "router"])
  description = "Default router for the workspace"

  network = google_compute_network.network.id
}

resource "google_compute_router_nat" "default_gateway" {
  name = join("-", [var.workspace.name, "nat", "gateway"])

  router                             = google_compute_router.default_router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

module "ssh_service" {
  source = "./modules/service"

  name = "ssh"

  desktop_ip = join("/", [var.user.ip, "32"])
  port       = 22
  index      = 1
  // This is an image family
  compute_image        = "bounce-debian-11"
  dns_zone             = "lab-wansho-fr"
  notification_channel = "ALERT on workspace Lab v1"

  back_network = {
    id              = google_compute_network.network.id
    base_cidr_block = local.base_cidr_block
  }
}

module "http_service" {
  source = "./modules/service"

  name = "http"

  desktop_ip = join("/", [var.user.ip, "32"])
  port       = 443
  index      = 2
  // This is an image family
  compute_image        = "envoy-debian-11"
  dns_zone             = "lab-wansho-fr"
  notification_channel = "ALERT on workspace Lab v1"

  back_network = {
    id              = google_compute_network.network.id
    base_cidr_block = local.base_cidr_block
  }
}

module "workstation" {
  source = "./modules/workstation"

  username      = var.user.name
  userkey       = var.user.key
  workspacename = var.workspace.name
  subnet_id     = google_compute_subnetwork.subnetwork.id
} 