output "access_hosts" {
  value = {
    ssh  = module.ssh_service.external_lb_name,
    http = module.http_service.external_lb_name
  }
  description = "FQDN to access each service exposed for the workstation."
}