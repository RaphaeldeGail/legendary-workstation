<!-- BEGIN_TF_DOCS -->
# Legendary Workstation

This code sets up a plateform for managing a development environment in Google Cloud.

Along with a development server, securized networking access are provided.

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.1.2 |
| google | ~> 4.5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_network.network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| core | Core unit of the workstation environment | ```object({ network = object({ name = string base_cidr_block = string }) })``` | n/a |
| project\_id | ID of the project. | `string` | n/a |
| region | Geographical *region* for Google Cloud Platform. | `string` | n/a |

## Outputs

No outputs.
<!-- END_TF_DOCS -->