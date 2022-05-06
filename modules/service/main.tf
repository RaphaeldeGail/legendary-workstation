/**
 * # Service
 */

locals {
    host_network = [var.name, "host", "network"]
    host_subnetwork = ["main","subnet"]
    base_subnetwork = [var.name, "subnet"]
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
  name          = join("-", local.host_subnetwork)
  description   = title(join(" ", concat(local.host_subnetwork, ["in"], local.host_network)))
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
  name          = join("-", local.base_subnetwork)
  description   = title(join(" ", concat(local.base_subnetwork, ["in", var.name, "network"])))
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

data "google_netblock_ip_ranges" "legacy-hcs" {
  range_type = "legacy-health-checkers"
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

resource "google_compute_instance_template" "main" {
  name        = join("-", [var.name, "template", "v${replace(var.full_version, ".", "-")}"])
  description = "This template is used for ${var.name} service"

  tags                 = [var.name]
  instance_description = "${var.name} service"
  machine_type         = "f1-micro"
  can_ip_forward       = true

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  disk {
    source_image = "custom-ubuntu"
    disk_size_gb = 20
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.host_subnetwork.id
  }
  network_interface {
    subnetwork = google_compute_subnetwork.base_subnetwork.id
  }

  metadata = var.metadata

  lifecycle {
    create_before_destroy = true
  }
}

data "google_compute_zones" "available" {
}

resource "google_compute_instance_group_manager" "main" {
  count = min(length(data.google_compute_zones.available.names), 2)

  name               = join("-", [var.name, "group-manager", count.index])
  description        = "Group manager for ${var.name} - zone ${data.google_compute_zones.available.names[count.index]} (${count.index})"
  base_instance_name = join("-", [var.name, count.index])
  zone               = data.google_compute_zones.available.names[count.index]

  version {
    instance_template = google_compute_instance_template.main.id
  }

  target_pools = [count.index == 0 ? google_compute_target_pool.default.id : google_compute_target_pool.main.id]
  target_size  = 1
}

resource "google_compute_http_health_check" "default" {
  name               = "default"
  port               = 80
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_target_pool" "default" {
  name        = join("-", [var.name, "pool", "failover"])
  description = "Pool of servers for ${var.name}"

  instances        = null
  session_affinity = "CLIENT_IP"

  health_checks = [
    google_compute_http_health_check.default.name,
  ]
}

resource "google_compute_target_pool" "main" {
  name        = join("-", [var.name, "pool", "main"])
  description = "Pool of servers for ${var.name}"

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

  name                  = join("-", [var.name, "frontend"])
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "22"
  target                = google_compute_target_pool.main.id
  network_tier          = "PREMIUM"
}