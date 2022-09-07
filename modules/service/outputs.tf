output "external_lb_name" {
  value       = google_dns_record_set.frontend_dn.name
  description = "FQDN for the loadbalancer of the service"
}