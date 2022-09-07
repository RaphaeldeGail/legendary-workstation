<!-- BEGIN_TF_DOCS -->
# Workstation

## Requirements

No requirements.

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_disk.boot_disk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_disk_resource_policy_attachment.backup_policy_attachment](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk_resource_policy_attachment) | resource |
| [google_compute_instance.workstation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_resource_policy.backup_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy) | resource |
| [google_service_account.bucket_service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_storage_bucket.shared_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.shared_bucket_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| subnet\_id | The ID of thesubnetwork to which the workstation will be bound. | `string` | n/a |
| userkey | SSH public key of the user that will inherit the workstation. | `string` | n/a |
| username | Name of the user that will inherit the workstation. May only contains lowercase letters. | `string` | n/a |
| workspacename | The name of the workspace to which the workstation will belong. | `string` | n/a |

## Outputs

No outputs.
<!-- END_TF_DOCS -->