variable "name" {
  type        = string
  description = "Name of the service. It may be the name of a protocol (HTTP) or any name. May only contains lowercase letters."

  validation {
    condition     = can(regex("^[a-z]*$", var.name))
    error_message = "The service name should be a valid name with only lowercase letters allowed."
  }
}

variable "desktop_ip" {
  type        = string
  description = "Public IP address of the desktop to connect to the workstation."
}

variable "port" {
  type        = number
  description = "Port number for service to expose. Should be related to the protocol (HTTP, SSH)."
}

variable "back_network" {
  type = object({
    id              = string
    base_cidr_block = string
  })
  description = "Workstation network characteristics. Including the google **id** of the network and the **base_cidr_block** for authorized ranges of IP addresses."
}

variable "metadata" {
  type        = map(string)
  default     = {}
  description = "Metadata input for service instances."
}

variable "index" {
  type        = number
  description = "A global index of the service which may not repeat itself among different instanciation."
}

variable "compute_image" {
  type        = string
  description = "The compute image family to build instance from, for this service."
}

variable "service_account" {
  type        = string
  default     = null
  description = "Email for the service account bound to the service. Defaults to null."
}

variable "project_wide_ssh_keys" {
  type        = bool
  default     = false
  description = "If true, the service instances will allow any SSH keys metadata set at the project level to be added."
}