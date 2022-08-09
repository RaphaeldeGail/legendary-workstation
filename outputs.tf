output "access_ips" {
  value = {
    ssh  = module.ssh_service.external_lb_address,
    http = module.http_service.external_lb_address
  }
  description = "Public IP addresses to access each service exposed for the workstation."
}