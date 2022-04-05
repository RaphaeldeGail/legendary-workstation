<!-- BEGIN_TF_DOCS -->
# Service

## Requirements

No requirements.

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_network.host_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_route.route](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route) | resource |
| [google_compute_subnetwork.base_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.host_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| base\_network | Base network characteristics | ```object({ name = string base_cidr_block = string id = string })``` | n/a |
| destination\_ip | IP address of main destination for the service | `string` | n/a |
| name | Name of the service | `string` | n/a |

## Outputs

No outputs.
<!-- END_TF_DOCS -->