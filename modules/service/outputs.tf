output "external_lb_address" {
  value       = min(length(data.google_compute_zones.available.names), 1) == 0 ? null : google_compute_forwarding_rule.front_loadbalancer[0].ip_address
  description = "The IPv4 IP address for the loadbalancer of the service"
}