variable "workspace" {
  type = object({
    name       = string
    project_id = string
    region     = string
  })
  description = "Core unit of the workstation environment"
}

variable "user" {
  type = object({
    name       = string
    public_key = string
    desktop_ip = string
  })
  description = "The user who will have access to the workstation"
  sensitive   = true
}