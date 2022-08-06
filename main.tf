/**
 * # Legendary Workstation
 * 
 * This code sets up a plateform for managing a development environment in Google Cloud, similar to a local environment (local virtual machine)
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
 * Please refer to the documentation in the packer directory.
 *
 * Set the values of the required variables in terraform.tfvars and set the name of the images you built with packer in the main code.
 *
 * Authenticate to Google Cloud Platform with a relevant account or set the environment variable *GOOGLE_APPLICATION_CREDENTIALS* to the path of a JSON service account key.
 *
 * Simply run terraform apply.
 *
 * ## Upcoming features
 *
 * - Improve variables definition and usage
 * - Build a module to create multiple workstations
 * - Improve image builds
 * - Testing the platform
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
  project = var.workspace.project_id
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

  desktop_ip = var.user.desktop_ip
  port       = 22
  index      = 1
  // This is an image family
  compute_image = "bounce-ubuntu-20"

  back_network = {
    id              = google_compute_network.network.id
    base_cidr_block = local.base_cidr_block
  }

  metadata = {
    user-data = trimspace(templatefile("./bounce-config.tpl", { ssh_public = var.user.public_key, username = var.user.name }))
  }
}

module "http_service" {
  source = "./modules/service"

  name = "http"

  desktop_ip = var.user.desktop_ip
  port       = 443
  index      = 2
  // This is an image family
  compute_image = "envoy-ubuntu-20"

  back_network = {
    id              = google_compute_network.network.id
    base_cidr_block = local.base_cidr_block
  }

  metadata = {
    user-data = trimspace(templatefile("./envoy-config.tpl", {}))
  }
}

resource "google_compute_disk" "data_disk" {
  name        = "workstation-data-disk"
  description = "Supplementary data disk for the workstation"

  size                      = 10
  type                      = "pd-standard"
  physical_block_size_bytes = 4096
  zone                      = "europe-west1-b"
}

resource "google_compute_resource_policy" "backup_policy" {
  name = join("-", ["data", "disk", "backup", "policy"])

  region = var.workspace.region
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "15:00"
      }
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "backup_policy_attachment" {
  name = google_compute_resource_policy.backup_policy.name
  disk = google_compute_disk.data_disk.name
  zone = "europe-west1-b"
}

resource "google_service_account" "bucket_service_account" {
  account_id   = "workstation-account"
  description  = "Service account for the workstation"
  display_name = "Workstation account"
}

resource "google_storage_bucket" "shared_bucket" {
  name = "shared-bucket-1605"

  location                    = "EU"
  force_destroy               = true
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "shared_bucket_member" {
  bucket = google_storage_bucket.shared_bucket.name
  role   = "roles/storage.objectAdmin"
  member = join(":", ["serviceAccount", google_service_account.bucket_service_account.email])
}

resource "google_compute_instance" "workstation" {
  name        = "workstation"
  description = "Workstation instance"

  zone           = "europe-west1-b"
  tags           = [var.workspace.name]
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
    startup-script         = "mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb; mkdir -p /mnt/disks/diskb; mount -o discard,defaults /dev/sdb /mnt/disks/diskb; chmod a+w /mnt/disks/diskb; echo '/dev/sdb /mnt/disks/diskb ext4 discard,defaults,rw 0 2' >> /etc/fstab"
    block-project-ssh-keys = true
    ssh-keys               = join(":", [trimspace(var.user.name), trimspace(var.user.public_key)])
  }

}