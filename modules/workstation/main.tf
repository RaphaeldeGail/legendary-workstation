/**
 * # Workstation
 *
 * This module creates a workstation for development needs, with a backup policy of the workstation disk and a GCS bucket mounted on the workstation for sharing files.
 *
 * ## Infrastructure description
 *
 * The module creates an instance with a boot disk (OS ubuntu 20.04).
 *
 * The boot disk has a backup policy for recovery
 *
 * A GCS bucket is also created and the workstation is equiped with GCSfuse libraries in order to mount it as a local filesystem.
 *
 * The service account bound to the workstation has specific read/write access to the bucket.
 *
 * The user of the workstation can then easily share items with the workstation by using the GCS interface and the local filesystem.
 *
 * ## Usage
 *
 * Simply call the module as:
 *
 * ```hcl
 * module "workstation" {
 *  source = "./modules/workstation"
 *
 *  username      = var.user.name
 *  userkey       = var.user.key
 *  workspacename = var.workspace.name
 *  subnet_id     = google_compute_subnetwork.subnetwork.id
 * } 
 * ```
 *
 * ## Versioning
 *
 * The local.version variable represents the version of the module.
 *
 */
terraform {
  required_version = "~> 1.1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.30.0"
    }
  }
}

locals {
  // This is the version of the module
  version = "1-0-0"
}

data "google_compute_zones" "available" {
}

resource "google_compute_disk" "boot_disk" {
  name        = join("-", [var.username, "boot", "disk"])
  description = "Boot disk for the workstation of ${var.username}"

  image                     = "ubuntu-2004-lts"
  size                      = 100
  type                      = "pd-standard"
  physical_block_size_bytes = 4096
  zone                      = data.google_compute_zones.available.names[0]
}

resource "google_compute_resource_policy" "backup_policy" {
  name = join("-", [var.username, "backup", "policy"])

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 7
        start_time    = "19:00"
      }
    }
    retention_policy {
      max_retention_days = 15
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "backup_policy_attachment" {
  name = google_compute_resource_policy.backup_policy.name
  disk = google_compute_disk.boot_disk.name
  zone = data.google_compute_zones.available.names[0]
}

resource "google_service_account" "bucket_service_account" {
  account_id   = join("-", [var.username, "service", "account"])
  description  = "Service account for ${var.username} workstation"
  display_name = "${title(var.username)} workstation account"
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "google_storage_bucket" "shared_bucket" {
  name = join("-", [var.username, "bucket", tostring(random_id.bucket_id.dec)])

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
  name        = join("-", [var.username, "workstation"])
  description = "Workstation instance for ${var.username}"

  zone           = data.google_compute_zones.available.names[0]
  tags           = [var.workspacename]
  machine_type   = "e2-medium"
  can_ip_forward = false

  service_account {
    email  = google_service_account.bucket_service_account.email
    scopes = ["cloud-platform"]
  }

  scheduling {
    provisioning_model  = "STANDARD"
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    automatic_restart   = true
  }

  boot_disk {
    device_name = google_compute_disk.boot_disk.name
    source      = google_compute_disk.boot_disk.id
    auto_delete = false
    mode        = "READ_WRITE"
  }

  network_interface {
    subnetwork = var.subnet_id
  }

  metadata = {
    block-project-ssh-keys = true
    ssh-keys               = join(":", [trimspace(var.username), trimspace(var.userkey)])
    user-data              = templatefile("${path.module}/cloud-config.yaml.tftpl", { bucket = google_storage_bucket.shared_bucket.name })
  }
}