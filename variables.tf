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

variable "rsa_key" {
  type        = string
  description = "RSA private key for SSH server. Confidential, should only be set by environment variable *TF_VAR_rsa_key*"
}

variable "rsa_pub" {
  type        = string
  description = "RSA public key for SSH server. Confidential, should only be set by environment variable *TF_VAR_rsa_pub*"
}

variable "dsa_key" {
  type        = string
  description = "DSA private key for SSH server. Confidential, should only be set by environment variable *TF_VAR_dsa_key*"
}

variable "dsa_pub" {
  type        = string
  description = "DSA public key for SSH server. Confidential, should only be set by environment variable *TF_VAR_dsa_pub*"
}

variable "ssh_pub" {
  type        = string
  description = "User public key for SSH authentication. Confidential, should only be set by environment variable *TF_VAR_ssh_pub*"
}