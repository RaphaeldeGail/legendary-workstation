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

  compute_image = "projects/lab-v1-0hw3q17w6a1y30jo-a5114/global/images/bounce-v1658500063-ubuntu-20"
  back_network = {
    name            = var.core.network.name
    base_cidr_block = var.core.network.base_cidr_block
    id              = google_compute_network.network.id
  }
  metadata = {
    user-data              = trimspace(templatefile("./cloud-config.tpl", { ssh_public = var.ssh_pub }))
    startup-script         = trimspace(templatefile("./startup-script.tpl", { local_ip = "86.70.78.151/32" }))
    block-project-ssh-keys = false
  }
}

module "http_service" {
  source = "./modules/service"

  name           = "http"
  full_version   = "1.0.1"
  destination_ip = "86.70.78.151/32"
  port           = 443

  index = 2

  compute_image = "projects/lab-v1-0hw3q17w6a1y30jo-a5114/global/images/envoy-v1657901517-ubuntu-20"
  back_network = {
    name            = var.core.network.name
    base_cidr_block = var.core.network.base_cidr_block
    id              = google_compute_network.network.id
  }
  metadata = {
    user-data              = trimspace(templatefile("./cloud-config.tpl", { ssh_public = var.ssh_pub }))
    startup-script         = trimspace(templatefile("./startup-script.tpl", { local_ip = "86.70.78.151/32" }))
    block-project-ssh-keys = true
  }
}

/*
resource "google_privateca_ca_pool" "default_ca" {
  name     = join("-", ["wansho", "ca", "pool", "123"])
  location = var.region
  tier     = "ENTERPRISE"
  publishing_options {
    publish_ca_cert = true
    publish_crl     = false
  }
  issuance_policy {
    allowed_issuance_modes {
      allow_csr_based_issuance    = true
      allow_config_based_issuance = false
    }
    identity_constraints {
      allow_subject_passthrough           = true
      allow_subject_alt_names_passthrough = true
    }
    baseline_values {
      ca_options {
        is_ca = true
      }
      key_usage {
        base_key_usage {
          digital_signature  = true
          content_commitment = true
          key_encipherment   = false
          data_encipherment  = true
          key_agreement      = true
          cert_sign          = false
          crl_sign           = true
          decipher_only      = true
        }
        extended_key_usage {
          server_auth      = true
          client_auth      = false
          email_protection = true
          code_signing     = true
          time_stamping    = true
        }
      }
    }
  }
}

resource "google_privateca_certificate_authority" "default" {
  // This example assumes this pool already exists.
  // Pools cannot be deleted in normal test circumstances, so we depend on static pools
  pool                     = google_privateca_ca_pool.default_ca.name
  certificate_authority_id = "wansho-lab-root-ca"
  location                 = var.region
  config {
    subject_config {
      subject {
        organization = "Wansho Lab"
        common_name  = "Wansho Lab Root CA"
      }
    }
    x509_config {
      ca_options {
        is_ca                  = true
        max_issuer_path_length = 10
      }
      key_usage {
        base_key_usage {
          digital_signature  = true
          content_commitment = true
          key_encipherment   = false
          data_encipherment  = true
          key_agreement      = true
          cert_sign          = true
          crl_sign           = true
          decipher_only      = true
        }
        extended_key_usage {
          server_auth      = true
          client_auth      = false
          email_protection = true
          code_signing     = true
          time_stamping    = true
        }
      }
    }
  }
  lifetime = "86400s"
  key_spec {
    algorithm = "RSA_PKCS1_4096_SHA256"
  }
}
*/

resource "google_compute_disk" "data_disk" {
  name                      = "data-disk"
  description               = "Data Disk"
  size                      = 10
  type                      = "pd-standard"
  physical_block_size_bytes = 4096
  zone                      = "europe-west1-b"
}

resource "google_compute_resource_policy" "backup_policy" {
  name   = join("-", ["backup", "policy"])
  region = var.region
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
  account_id   = "bucket-account"
  description  = "Bucket Account"
  display_name = "Bucket Account"
}

resource "google_storage_bucket" "shared_bucket" {
  name          = "shared-bucket-1605"
  location      = "EU"
  force_destroy = true
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "shared_bucket_member" {
  bucket = google_storage_bucket.shared_bucket.name
  role   = "roles/storage.objectAdmin"
  member = join(":", ["serviceAccount", google_service_account.bucket_service_account.email])
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
    startup-script         = "mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb; mkdir -p /mnt/disks/diskb; mount -o discard,defaults /dev/sdb /mnt/disks/diskb; chmod a+w /mnt/disks/diskb; echo '/dev/sdb /mnt/disks/diskb ext4 discard,defaults,rw 0 2' >> /etc/fstab"
    block-project-ssh-keys = true
    ssh-keys               = join(":", ["raphael", trimspace(var.ssh_pub)])
  }

}