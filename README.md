<!-- BEGIN_TF_DOCS -->
# Legendary Workstation

This code sets up a plateform for managing a development environment in Google Cloud, similar to a local environment (local virtual machine).

## Infrastructure description

The code creates a private Google network, hosting a workload instance for development purpose.

The instance is bound to a supplementary data disk with a backup strategy in order to prevent user data loss.

The instance also has access to a dedicated bucket for ease of storing.

The private Google network has access to the internet via a NAT gateway with dynamic output IP addresses.

The platform also has dedicated access for SSH and HTTP services through group of gateways routed to a single IP address.

The gateways are exposed behind Layer 4 loadbalancers.

## Usage

Before building the platform, you should build your own image for SSH and HTTP gateways with packer.

Please refer to the documentation in the packer directory.

Set the values of the required variables in terraform.tfvars and set the name of the images you built with packer in the main code.

Authenticate to Google Cloud Platform with a relevant account or set the environment variable *GOOGLE\_APPLICATION\_CREDENTIALS* to the path of a JSON service account key.

Simply run:

```bash
terraform init
terraform apply
```

## Upcoming features

- Improve variables definition and usage [X]
- Build a module to create multiple workstations []
- Improve image builds [X]
- Testing the platform []
- Improve workstation data disk mount []
- Add GCS Fuse to mount the GCS bucket to the workstation []

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.1.2 |
| google | >= 4.5.0 |

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
| [google_compute_router.default_router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.default_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_compute_subnetwork.subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_service_account.bucket_service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_storage_bucket.shared_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.shared_bucket_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| user | The user who will have access to the workstation. Requires a **name**, the content of a public **key** for SSH authentication and the public IP address of the user.  The **name** attribute must follow UNIX name standards. the SSH public **key** should be one line and the *ip* attribute should be in the form *X.X.X.X* as standard IPv4. | ```object({ name = string key = string ip = string })``` | n/a |
| workspace | The workspace that will be created on GCP. Requires a **name**, the ID of a GCP **project** and the **region** of deployment on GCP. The **name** attributes must contain only lowercase letters. | ```object({ name = string project = string region = string })``` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| access\_ips | Public IP addresses to access each service exposed for the workstation. |
<!-- END_TF_DOCS -->