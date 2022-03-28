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