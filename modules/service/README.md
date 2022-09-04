<!-- BEGIN_TF_DOCS -->
# Service

This module creates the required infrastructure to expose a service for the workstation (SSH access, HTTPS access, etc.)

## Infrastructure description

The module creates a dedicated network, separated from the workstation network.

Instances, managed by a group, resides on both networks and are able to route traffic from one to another.

The instances are only exposed by a dedicated route linked to the desktop, and a dedicated firewall.

The instances are accessed from the internet by a public load balancer (forwarding rule).

Apart from the port to expose, instances can also be configured with meta-data for specific configurations

## Usage

Simply call the module as:

```hcl
module "http_service" {
 source = "./modules/service"

 name           = "http"
 desktop_ip     = "86.70.78.151/32"
 port           = 443
 index          = 2
 compute_image  = "envoy-v1659108720-ubuntu-20"

 back_network   = {
   name            = var.core.network.name
   base_cidr_block = var.core.network.base_cidr_block
   id              = google_compute_network.network.id
 }

 metadata       = {
   user-data       = trimspace(templatefile("./envoy-config.tpl", {}))
 }
}
```

The module expects an index which must be different for every instanciation of the module.

## Versioning

The local.version variable represents the version of the module.

The module may be applied an infinite number of times with the same version, since the different instance templates are always timestamped.

serveral instance template from the version 1-0-0 for http service will be created as http-v1-0-0-template-20220703163611 or http-v1-0-0-template-20220806135603, etc.

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.1.2 |
| google | >= 4.30.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_address.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_firewall.from_back](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.healthcheck](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.legacy_healthcheck](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.to_front](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_forwarding_rule.front_loadbalancer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | resource |
| [google_compute_health_check.auto_healing](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | resource |
| [google_compute_http_health_check.loadbalancer_healthcheck](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_http_health_check) | resource |
| [google_compute_instance_group_manager.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager) | resource |
| [google_compute_instance_template.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template) | resource |
| [google_compute_network.front_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_route.route](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route) | resource |
| [google_compute_subnetwork.back_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.front_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_target_pool.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_pool) | resource |
| [google_compute_target_pool.failover](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_pool) | resource |
| [google_monitoring_alert_policy.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_dashboard.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_dashboard) | resource |
| [google_compute_image.image](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |
| [google_monitoring_notification_channel.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/monitoring_notification_channel) | data source |
| [google_netblock_ip_ranges.legacy_healthcheck](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |
| [google_netblock_ip_ranges.service_healthcheck](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| back\_network | Workstation network characteristics. Including the google **id** of the network and the **base\_cidr\_block** for authorized ranges of IP addresses. | ```object({ id = string base_cidr_block = string })``` | n/a |
| compute\_image | The compute image family to build instance from, for this service. | `string` | n/a |
| desktop\_ip | Public IP address of the desktop to connect to the workstation. | `string` | n/a |
| index | A global index of the service which may not repeat itself among different instanciation. | `number` | n/a |
| metadata | Metadata input for service instances. | `map(string)` | `{}` |
| name | Name of the service. It may be the name of a protocol (HTTP) or any name. May only contains lowercase letters. | `string` | n/a |
| port | Port number for service to expose. Should be related to the protocol (HTTP, SSH). | `number` | n/a |
| project\_wide\_ssh\_keys | If true, the service instances will allow any SSH keys metadata set at the project level to be added. | `bool` | `false` |
| service\_account | Email for the service account bound to the service. Defaults to null. | `string` | `null` |

## Outputs

| Name | Description |
|------|-------------|
| external\_lb\_address | The IPv4 IP address for the loadbalancer of the service |
<!-- END_TF_DOCS -->