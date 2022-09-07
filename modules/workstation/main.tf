/**
 * # Workstation
 *
 *
 */

resource "google_compute_disk" "boot_disk" {
  name        = join("-", [var.username, "boot", "disk"])
  description = "Boot disk for the workstation of ${var.username}"

  image                     = "ubuntu-2004-lts"
  size                      = 10
  type                      = "pd-standard"
  physical_block_size_bytes = 4096
  zone                      = "europe-west1-b"
}

resource "google_compute_resource_policy" "backup_policy" {
  name = join("-", [var.username, "boot", "disk", "backup", "policy"])

  #region = var.workspace.region
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
  disk = google_compute_disk.boot_disk.name
  zone = "europe-west1-b"
}

resource "google_service_account" "bucket_service_account" {
  account_id   = join("-", [var.username, "account"])
  description  = "Service account for ${var.username} workstation"
  display_name = "Workstation account"
}

resource "google_storage_bucket" "shared_bucket" {
  name = join("-", [var.username, "bucket", "1605"])

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

  zone           = "europe-west1-b"
  tags           = [var.workspacename]
  machine_type   = "e2-small"
  can_ip_forward = false

  service_account {
    email  = google_service_account.bucket_service_account.email
    scopes = ["cloud-platform"]
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
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
    user-data              = file("${path.module}/cloud-config.yaml")
  }
}