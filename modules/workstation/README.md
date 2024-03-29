<!-- BEGIN_TF_DOCS -->
# Workstation

This module creates a workstation for development needs, with a backup policy of the workstation disk and a GCS bucket mounted on the workstation for sharing files.

## Infrastructure description

The module creates an instance with a boot disk (OS ubuntu 20.04).

The boot disk has a backup policy for recovery

A GCS bucket is also created and the workstation is equiped with GCSfuse libraries in order to mount it as a local filesystem.

The service account bound to the workstation has specific read/write access to the bucket.

The user of the workstation can then easily share items with the workstation by using the GCS interface and the local filesystem.

## Usage

Simply call the module as:

```hcl
module "workstation" {
 source = "./modules/workstation"

 username      = var.user.name
 userkey       = var.user.key
 workspacename = var.workspace.name
 subnet_id     = google_compute_subnetwork.subnetwork.id
}
```

## Versioning

The local.version variable represents the version of the module.

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
| [google_compute_disk.boot_disk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_disk_resource_policy_attachment.backup_policy_attachment](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk_resource_policy_attachment) | resource |
| [google_compute_instance.workstation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_resource_policy.backup_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy) | resource |
| [google_service_account.bucket_service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_storage_bucket.shared_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.shared_bucket_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [random_id.bucket_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| subnet\_id | The ID of the subnetwork to which the workstation will be bound. | `string` | n/a |
| userkey | SSH public key of the user that will inherit the workstation. | `string` | n/a |
| username | Name of the user that will inherit the workstation. May only contains lowercase letters. | `string` | n/a |
| workspacename | The name of the workspace to which the workstation will belong. | `string` | n/a |

## Outputs

No outputs.
<!-- END_TF_DOCS -->