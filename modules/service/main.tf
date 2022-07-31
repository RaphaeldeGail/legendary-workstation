/**
 * # Service
 */

locals {
    front_network = [var.name, "front", "network"]
    front_subnetwork = [var.name, "main","subnet"]
    back_subnetwork = [var.name, "back", "subnet"]
    route = [var.name, "route", "to", "destination", "ip"]
    front_firewall = ["allow", "from", "destination", "to", var.name, "tcp", tostring(var.port)]
    back_firewall = ["allow", "from", var.name, "to", "workspace", "tcp", tostring(var.port)]
    healthcheck_firewall = ["allow", "from", "healthchecks", "to", var.name, "tcp", tostring(80)]
    template = [var.name, "template", "v${replace(var.full_version, ".", "-")}"]
}

resource "google_compute_network" "front_network" {
  name                            = join("-", local.front_network)
  description                     = title(join(" ", local.front_network))
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "front_subnetwork" {
  name          = join("-", local.front_subnetwork)
  description   = title(join(" ", concat(local.front_subnetwork, ["in"], local.front_network)))
  network       = google_compute_network.front_network.id

  ip_cidr_range = cidrsubnet("172.16.0.0/12", 10, 0)
}

resource "google_compute_route" "route" {
  name             = join("-", local.route)
  description      = title(join(" ",concat(local.route, [var.destination_ip])))
  network          = google_compute_network.front_network.name

  dest_range       = var.destination_ip
  next_hop_gateway = "default-internet-gateway"
  priority         = 10
  tags             = [var.name]
}

resource "google_compute_subnetwork" "back_subnetwork" {
  name          = join("-", local.back_subnetwork)
  description   = title(join(" ", concat(local.back_subnetwork, ["in", var.name, "network"])))
  network       = var.back_network.id

  ip_cidr_range = cidrsubnet(var.back_network.base_cidr_block, 2, var.index)
}

resource "google_compute_firewall" "to_front" {
  name        = join("-", local.front_firewall)
  description = title(join(" ", local.front_firewall))
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
  name        = join("-", local.back_firewall)
  description = title(join(" ", local.back_firewall))
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
  name        = join("-", local.healthcheck_firewall)
  description = title(join(" ", local.healthcheck_firewall))
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

resource "google_compute_instance_template" "main" {
  name        = join("-", local.template)
  description = title(join(" ", local.template))

  tags                 = [var.name]
  instance_description = title("Instance based on ${join(" ", local.template)}")
  machine_type         = "f1-micro"
  can_ip_forward       = true

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  disk {
    source_image = var.compute_image
    disk_size_gb = 20
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.front_subnetwork.id
  }
  network_interface {
    subnetwork = google_compute_subnetwork.back_subnetwork.id
  }

  metadata = merge(var.metadata, { block-project-ssh-keys=true })

  dynamic "service_account" {
    for_each = var.service_account == null ? [] : [""]
    content {
      email  = var.service_account
      scopes = ["cloud-platform"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "google_compute_zones" "available" {
}

resource "google_compute_instance_group_manager" "main" {
  count = min(length(data.google_compute_zones.available.names), 2)

  name               = join("-", [var.name, "group", count.index])
  description        = title(join(" ", [var.name, "group", count.index]))
  base_instance_name = join("-", [var.name, replace(var.full_version, ".", "-"), count.index])
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