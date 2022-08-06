variable "workspace" {
  type = object({
    name    = string
    project = string
    region  = string
  })
  description = "The workspace that will be created on GCP. Requires a **name**, the ID of a GCP **project** and the **region** of deployment on GCP. The **name** attributes must contain only lowercase letters."

  validation {
    condition     = can(regex("^[a-z]*$", var.workspace.name))
    error_message = "The workspace name should be a valid name with only lowercase letters allowed."
  }
}

variable "user" {
  type = object({
    name = string
    key  = string
    ip   = string
  })
  description = "The user who will have access to the workstation. Requires a **name**, the content of a public **key** for SSH authentication and the public IP address of the user.\n The **name** attribute must follow UNIX name standards. the SSH public **key** should be one line and the *ip* attribute should be in the form *X.X.X.X* as standard IPv4."
  sensitive   = true

  validation {
    condition     = can(regex("^[a-z][-a-z0-9]*$", var.user.name))
    error_message = "The user name should comply with UNIX standards and the NAME_REGEX \"^[a-z][-a-z0-9]*$\"."
  }
  validation {
    condition     = can(regex("^([0-9]){1,3}.([0-9]){1,3}.([0-9]){1,3}.([0-9]){1,3}$", var.user.ip))
    error_message = "The user IP address should be in the form *X.X.X.X*, with X a number between 0 and 255 as standard IPv4."
  }
}