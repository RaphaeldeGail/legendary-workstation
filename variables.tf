variable "project_id" {
  type        = string
  description = "ID of the project."
  nullable    = false
}

variable "region" {
  type        = string
  description = "Geographical *region* for Google Cloud Platform."
  nullable    = false
}

variable "core" {
  type = object({
    network = object({
      name            = string
      base_cidr_block = string
    })
  })
  description = "Core unit of the workstation environment"
}

variable "ssh_pub" {
  type        = string
  description = "User public key for SSH authentication. Confidential, should only be set by environment variable *TF_VAR_ssh_pub*"
}