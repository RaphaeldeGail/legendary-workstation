/**
 * # Service
 */
terraform {
  required_version = "~> 1.1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.30.0"
    }
  }
}

locals {
    front_network = [var.name, "front", "network"]
    ip_cidr_range = "172.16.0.0/12"
    version = replace(var.full_version, ".", "-")
    template = [var.name, "v${local.version}", "template"]
    timestamp = tostring(formatdate("YYYYMMDDhhmmss", timestamp()))
}

resource "google_compute_network" "front_network" {
  name                            = join("-", local.front_network)
  description                     = join(" ", ["IP address range:", local.ip_cidr_range])

  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "front_subnetwork" {
  name          = join("-", [var.name, "front","subnet"])
  description   = null

  network       = google_compute_network.front_network.id
  ip_cidr_range = cidrsubnet(local.ip_cidr_range, 10, 0)
}

resource "google_compute_route" "route" {
  name             = join("-", [var.name, "route", "to", "desktop"])
  description      = "Route to the desktop public IP address"

  network          = google_compute_network.front_network.name
  dest_range       = var.destination_ip
  next_hop_gateway = "default-internet-gateway"
  priority         = 10
  tags             = [var.name]
}

resource "google_compute_subnetwork" "back_subnetwork" {
  name          = join("-", [var.name, "back", "subnet"])
  description   = null

  network       = var.back_network.id
  ip_cidr_range = cidrsubnet(var.back_network.base_cidr_block, 2, var.index)
}

resource "google_compute_firewall" "to_front" {
  name        = join("-", ["allow", "from", "desktop", "to", var.name, "tcp", tostring(var.port)])
  description = "Allow requests from the desktop public IP address to the ${var.name} service instances"

  network     = google_compute_network.front_network.id
  direction   = "INGRESS"
  priority    = 10

  allow {
    protocol = "tcp"
    ports    = [tostring(var.port)]
  }

  source_ranges = [var.destination_ip]
  target_tags   = [var.name]
}

resource "google_compute_firewall" "from_back" {
  name        = join("-", ["allow", "from", var.name, "to", "workspace", "tcp", tostring(var.port)])
  description = "Allow requests from the ${var.name} service to the workstation"

  network     = var.back_network.id
  direction   = "INGRESS"
  priority    = 10

  allow {
    protocol = "tcp"
    ports    = [tostring(var.port)]
  }

  source_tags = [var.name]
  target_tags = ["workspace"]
}

data "google_netblock_ip_ranges" "legacy_healthcheck" {
  range_type = "legacy-health-checkers"
}

resource "google_compute_firewall" "legacy_healthcheck" {
  name        = join("-", ["allow", "from", "healthchecks", "to", var.name, "tcp", tostring(80)])
  description = "Allow HTTP requests from Google healthchecks to ${var.name} service instances"
  network     = google_compute_network.front_network.id
  direction   = "INGRESS"
  priority    = 100

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = data.google_netblock_ip_ranges.legacy_healthcheck.cidr_blocks_ipv4
  target_tags   = [var.name]
}

data "google_compute_image" "custom_image" {
  name = var.compute_image
}

resource "google_compute_instance_template" "main" {
  name        = join("-", concat(local.template, [local.timestamp]))
  description = title(join(" ", local.template))

  tags                 = [var.name]
  instance_description = title("Instance based on ${join(" ", concat(local.template, ["build @", local.timestamp]))}")
  machine_type         = "e2-micro"
  can_ip_forward       = true
  metadata = merge(var.metadata, { block-project-ssh-keys=true })
  labels = {
    name    = var.name
    version = local.version
  }

  scheduling {
    provisioning_model = "SPOT"
    # Only STOP action is available for SPOT-type instances managed by a group
    instance_termination_action = "STOP"
    preemptible       = true
    automatic_restart = false
  }

  disk {
    source_image = data.google_compute_image.custom_image.id
    disk_size_gb = data.google_compute_image.custom_image.disk_size_gb
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.front_subnetwork.id
  }
  network_interface {
    subnetwork = google_compute_subnetwork.back_subnetwork.id
  }

  dynamic "service_account" {
    for_each = var.service_account == null ? [] : [""]
    content {
      email  = var.service_account
      scopes = ["cloud-platform"]
    }
  }

  lifecycle {
    # Create the new template before destroying the previous so the google manager can update itself before the old template is destroyed
    create_before_destroy = true
    ignore_changes = [
      # Ignore changes to name, description and instance_description because all contain timestamp
      # instead name and full_version are stored in labels that will trigger an update if change
      name,
      instance_description,
    ]
  }
}

data "google_compute_zones" "available" {
}

resource "google_compute_instance_group_manager" "main" {
  count = min(length(data.google_compute_zones.available.names), 2)

  name               = join("-", [var.name, local.version, "group", data.google_compute_zones.available.names[count.index]])
  description        = "Manages  all instances of the ${var.name} service on version ${var.full_version} @Zone ${data.google_compute_zones.available.names[count.index]}"

  base_instance_name = join("-", [var.name, local.version, "service", data.google_compute_zones.available.names[count.index]])
  zone               = data.google_compute_zones.available.names[count.index]

  version {
    instance_template = google_compute_instance_template.main.id
  }

  target_pools = [count.index == 0 ? google_compute_target_pool.default.id : google_compute_target_pool.main.id]
  target_size  = 1
}

resource "google_compute_http_health_check" "default" {
  name               = join("-", [var.name, "default-healthcheck"])
  port               = 80
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_target_pool" "default" {
  name        = join("-", [var.name, "pool", "failover"])
  description = title(join("-", [var.name, "pool", "failover"]))

  instances        = null
  session_affinity = "CLIENT_IP"

  health_checks = [
    google_compute_http_health_check.default.name,
  ]
}

resource "google_compute_target_pool" "main" {
  name        = join("-", [var.name, "pool", "main"])
  description = title(join("-", [var.name, "pool", "main"]))

  instances        = null
  session_affinity = "CLIENT_IP"

  health_checks = [
    google_compute_http_health_check.default.name,
  ]

  backup_pool    = google_compute_target_pool.default.self_link
  failover_ratio = 0.5
}

resource "google_compute_forwarding_rule" "google_compute_forwarding_rule" {
  count = min(length(data.google_compute_zones.available.names), 1)

  name                  = join("-", [var.name, "frontend", "loadbalancer"])
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = tostring(var.port)
  target                = google_compute_target_pool.main.id
  network_tier          = "PREMIUM"
}