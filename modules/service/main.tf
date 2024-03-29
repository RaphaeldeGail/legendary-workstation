/**
 * # Service
 *
 * This module creates the required infrastructure to expose a service for the workstation (SSH access, HTTPS access, etc.)
 *
 * ## Infrastructure description
 *
 * The module creates a dedicated network, separated from the workstation network.
 *
 * Instances, managed by a group, resides on both networks and are able to route traffic from one to another.
 *
 * The instances are only exposed by a dedicated route linked to the desktop, and a dedicated firewall.
 *
 * The instances are accessed from the internet by a public load balancer (forwarding rule).
 *
 * Apart from the port to expose, instances can also be configured with meta-data for specific configurations
 *
 * ## Usage
 *
 * Simply call the module as:
 *
 * ```hcl
 * module "http_service" {
 *  source = "./modules/service"
 *
 *  name           = "http"
 *  desktop_ip     = "86.70.78.151/32"
 *  port           = 443
 *  index          = 2
 *  compute_image  = "envoy-v1659108720-ubuntu-20"
 *
 *  back_network   = {
 *    name            = var.core.network.name
 *    base_cidr_block = var.core.network.base_cidr_block
 *    id              = google_compute_network.network.id
 *  }
 *
 *  metadata       = {
 *    user-data       = file("./envoy-config.tpl")
 *  }
 * }
 * ```
 *
 * The module expects an index which must be different for every instanciation of the module.
 *
 * ## Versioning
 *
 * The local.version variable represents the version of the module.
 * 
 * The module may be applied an infinite number of times with the same version, since the different instance templates are always timestamped.
 *
 * serveral instance template from the version 1-0-0 for http service will be created as http-v1-0-0-template-20220703163611 or http-v1-0-0-template-20220806135603, etc.
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
  // The IP range for the front network
  ip_cidr_range = "172.16.0.0/12"
  // This is the version of the module
  version   = "1-1-0"
  name      = lower(var.name)
  template  = [local.name, "v${local.version}", "template"]
  timestamp = tostring(formatdate("YYYYMMDDhhmmss", timestamp()))
  labels = {
    name    = local.name
    version = local.version
  }
  startup-script = trimspace(templatefile("${path.module}/startup-script.tftpl", { local_ip = var.desktop_ip }))
}

resource "google_compute_network" "front_network" {
  name        = join("-", [local.name, "front", "network"])
  description = join(" ", ["IP address range:", local.ip_cidr_range])

  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "front_subnetwork" {
  name        = join("-", [local.name, "front", "subnet"])
  description = null

  network       = google_compute_network.front_network.id
  ip_cidr_range = cidrsubnet(local.ip_cidr_range, 10, 0)
}

resource "google_compute_route" "route" {
  name        = join("-", [local.name, "route", "to", "desktop"])
  description = "Route to the desktop public IP address"

  network          = google_compute_network.front_network.name
  dest_range       = var.desktop_ip
  next_hop_gateway = "default-internet-gateway"
  priority         = 10
  tags             = [local.name]
}

resource "google_compute_subnetwork" "back_subnetwork" {
  name        = join("-", [local.name, "back", "subnet"])
  description = null

  network       = var.back_network.id
  ip_cidr_range = cidrsubnet(var.back_network.base_cidr_block, 2, var.index)
}

resource "google_compute_firewall" "to_front" {
  name        = join("-", ["allow", "from", "desktop", "to", local.name, "tcp", tostring(var.port)])
  description = "Allow requests from the desktop public IP address to the ${local.name} service instances"

  network   = google_compute_network.front_network.id
  direction = "INGRESS"
  priority  = 10

  allow {
    protocol = "tcp"
    ports    = [tostring(var.port)]
  }

  source_ranges = [var.desktop_ip]
  target_tags   = [local.name]
}

resource "google_compute_firewall" "from_back" {
  name        = join("-", ["allow", "from", local.name, "to", "workspace", "tcp", tostring(var.port)])
  description = "Allow requests from the ${local.name} service to the workstation"

  network   = var.back_network.id
  direction = "INGRESS"
  priority  = 10

  allow {
    protocol = "tcp"
    ports    = [tostring(var.port)]
  }

  source_tags = [local.name]
  target_tags = ["workspace"]
}

data "google_netblock_ip_ranges" "legacy_healthcheck" {
  range_type = "legacy-health-checkers"
}

data "google_netblock_ip_ranges" "service_healthcheck" {
  range_type = "health-checkers"
}

resource "google_compute_firewall" "legacy_healthcheck" {
  name        = join("-", ["allow", "from", "legacy", "healthchecks", "to", local.name, "tcp", tostring(80)])
  description = "Allow HTTP requests from Google healthchecks to ${local.name} service instances"
  network     = google_compute_network.front_network.id
  direction   = "INGRESS"
  priority    = 100

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = data.google_netblock_ip_ranges.legacy_healthcheck.cidr_blocks_ipv4
  target_tags   = [local.name]
}

resource "google_compute_firewall" "healthcheck" {
  name        = join("-", ["allow", "from", "service", "healthchecks", "to", local.name, "tcp", tostring(80)])
  description = "Allow Google healthchecks to ${local.name} service instances"
  network     = google_compute_network.front_network.id
  direction   = "INGRESS"
  priority    = 100

  allow {
    protocol = "tcp"
    ports    = [tostring(var.port)]
  }

  source_ranges = data.google_netblock_ip_ranges.service_healthcheck.cidr_blocks_ipv4
  target_tags   = [local.name]
}

data "google_compute_image" "image" {
  family = var.compute_image
}

resource "google_compute_instance_template" "main" {
  name        = join("-", concat(local.template, [local.timestamp]))
  description = title(join(" ", local.template))

  tags                 = [local.name]
  instance_description = title("Instance based on ${join(" ", concat(local.template, ["build @", local.timestamp]))}")
  machine_type         = "e2-micro"
  can_ip_forward       = true
  metadata             = merge(var.metadata, { block-project-ssh-keys = var.project_wide_ssh_keys, startup-script = local.startup-script })
  labels               = local.labels

  scheduling {
    provisioning_model = "SPOT"
    # Only STOP action is available for SPOT-type instances managed by a group
    instance_termination_action = "STOP"
    preemptible                 = true
    automatic_restart           = false
  }

  disk {
    source_image = "global/images/family/${var.compute_image}"
    disk_size_gb = data.google_compute_image.image.disk_size_gb
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

resource "google_compute_health_check" "auto_healing" {
  name        = join("-", [local.name, "service", "autohealing"])
  description = "Auto healing health check via tcp for service instances ${local.name} ${local.version}"

  timeout_sec         = 1
  check_interval_sec  = 1
  healthy_threshold   = 4
  unhealthy_threshold = 5

  tcp_health_check {
    port               = var.port
    port_specification = "USE_FIXED_PORT"
  }
}

resource "google_compute_instance_group_manager" "main" {
  count = min(length(data.google_compute_zones.available.names), 2)

  name        = join("-", [local.name, local.version, "group", count.index])
  description = "Manages  all instances of the ${local.name} service on version ${local.version} @Zone ${data.google_compute_zones.available.names[count.index]}"

  base_instance_name = join("-", [local.name, local.version, "service", data.google_compute_zones.available.names[count.index]])
  zone               = data.google_compute_zones.available.names[count.index]
  target_pools       = [count.index == 0 ? google_compute_target_pool.failover.id : google_compute_target_pool.default.id]
  target_size        = 1

  version {
    name              = local.version
    instance_template = google_compute_instance_template.main.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.auto_healing.id
    initial_delay_sec = 30
  }

  update_policy {
    type                           = "PROACTIVE"
    minimal_action                 = "RESTART"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed                = 2
    max_unavailable_fixed          = 1
    replacement_method             = "SUBSTITUTE"
  }
}

resource "google_compute_http_health_check" "loadbalancer_healthcheck" {
  name        = join("-", [local.name, "loadbalancer", "healthcheck"])
  description = "Legacy HTTP healthcheck used by network load balancer for service ${local.name}"

  port               = 80
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_target_pool" "failover" {
  name        = join("-", [local.name, "pool", "failover"])
  description = "Failover pool for service ${local.name}"

  instances        = null
  session_affinity = "CLIENT_IP"
  health_checks = [
    google_compute_http_health_check.loadbalancer_healthcheck.name,
  ]
}

resource "google_compute_target_pool" "default" {
  name        = join("-", [local.name, "pool", "main"])
  description = "Default pool for service ${local.name}"

  instances        = null
  session_affinity = "CLIENT_IP"
  health_checks = [
    google_compute_http_health_check.loadbalancer_healthcheck.name,
  ]
  backup_pool    = google_compute_target_pool.failover.self_link
  failover_ratio = 0.5
}

resource "google_compute_address" "default" {
  name        = join("-", [local.name, "frontend", "ipaddress"])
  description = "The IP address for the frontend service ${local.name} in IPV4 format"

  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

data "google_dns_managed_zone" "dns_zone" {
  name = var.dns_zone
}

resource "google_dns_record_set" "frontend_dn" {
  name = "${local.name}-access.${data.google_dns_managed_zone.dns_zone.dns_name}"

  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  rrdatas      = [google_compute_address.default.address]
}

resource "google_compute_forwarding_rule" "front_loadbalancer" {
  count = min(length(data.google_compute_zones.available.names), 1)

  name        = join("-", [local.name, "frontend", "loadbalancer"])
  description = "Load balancer for service ${local.name}"

  labels                = local.labels
  ip_address            = google_compute_address.default.id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = tostring(var.port)
  target                = google_compute_target_pool.default.id
  network_tier          = "PREMIUM"
}

resource "google_monitoring_dashboard" "default" {
  dashboard_json = templatefile("${path.module}/dashboard.tftpl", { name = local.name, forwarding_rule_name = google_compute_forwarding_rule.front_loadbalancer[0].name, local_network = google_compute_network.front_network.name })
}

data "google_monitoring_notification_channel" "default" {
  display_name = var.notification_channel
}

resource "google_monitoring_alert_policy" "default" {
  display_name = title(join(" ", [upper(local.name), "service", "instances", "egress", "blockade"]))

  combiner              = "OR"
  enabled               = true
  notification_channels = [data.google_monitoring_notification_channel.default.name]
  user_labels           = local.labels

  alert_strategy {
    auto_close = "3600s"
  }

  conditions {
    display_name = "VM Instance - Egress bytes - below 0.01B"

    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"networking.googleapis.com/vm_flow/egress_bytes_count\" AND metric.labels.local_network = \"${google_compute_network.front_network.name}\""
      duration        = "0s"
      comparison      = "COMPARISON_LT"
      threshold_value = 0.01

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        percent = 100
      }
    }
  }
}