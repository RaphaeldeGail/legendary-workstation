variable "username" {
  type        = string
  description = "Name of the user that will inherit the workstation. May only contains lowercase letters."

  validation {
    condition     = can(regex("^[a-z]*$", var.username))
    error_message = "The username should be a valid name with only lowercase letters allowed."
  }
}

variable "userkey" {
  type        = string
  description = "SSH public key of the user that will inherit the workstation."
}

variable "workspacename" {
  type        = string
  description = "The name of the workspace to which the workstation will belong."
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnetwork to which the workstation will be bound."
}