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

| Name | Source | Version |
|------|--------|---------|
| http\_service | ./modules/service | n/a |
| ssh\_service | ./modules/service | n/a |

## Resources

| Name | Type |
|------|------|
| [google_compute_disk.data_disk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_disk_resource_policy_attachment.backup_policy_attachment](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk_resource_policy_attachment) | resource |
| [google_compute_instance.workstation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_network.network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_resource_policy.backup_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy) | resource |
| [google_compute_route.default_route](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route) | resource |
| [google_compute_router.nat_router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.nat_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_compute_subnetwork.subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_service_account.bucket_service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_storage_bucket.shared_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.shared_bucket_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| core | Core unit of the workstation environment | ```object({ network = object({ name = string base_cidr_block = string }) })``` | n/a |
| project\_id | ID of the project. | `string` | n/a |
| region | Geographical *region* for Google Cloud Platform. | `string` | n/a |
| ssh\_pub | User public key for SSH authentication. Confidential, should only be set by environment variable *TF\_VAR\_ssh\_pub* | `string` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| network | Main network characteristics |
<!-- END_TF_DOCS -->