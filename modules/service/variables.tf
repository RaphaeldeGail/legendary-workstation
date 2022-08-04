variable "name" {
  type        = string
  description = "Name of the service. It may be the name of a protocol (HTTP) or any name. Must be lowercase"
}

variable "desktop_ip" {
  type        = string
  description = "Public IP address of the desktop to connect to the workstation"
}

variable "port" {
  type        = number
  description = "Port number for service to expose. Should be related to the protocol (HTTP, SSH)"
}

variable "back_network" {
  type = object({
    id              = string
    base_cidr_block = string
  })
  description = "Main workstation network characteristics"
}

variable "metadata" {
  type        = map(string)
  description = "Metadata to input to service instances"
}

variable "index" {
  type        = number
  description = "A global index of the service which may not repeat itself among different instanciation"
}

variable "compute_image" {
  type        = string
  description = "The compute image name to build instance for this service"
}

variable "service_account" {
  type        = string
  description = "Email for the service account bound to the service. Defaults to null"
  default     = null
}