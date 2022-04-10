<!-- BEGIN_TF_DOCS -->
# Service

## Requirements

No requirements.

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.from_base](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.healthcheck](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.to_host](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_network.host_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_route.route](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route) | resource |
| [google_compute_subnetwork.base_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.host_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_netblock_ip_ranges.legacy-hcs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| base\_network | Base network characteristics | ```object({ name = string base_cidr_block = string id = string })``` | n/a |
| destination\_ip | IP address of main destination for the service | `string` | n/a |
| name | Name of the service | `string` | n/a |
| port | Port number for service | `number` | n/a |

## Outputs

No outputs.
<!-- END_TF_DOCS -->