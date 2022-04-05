variable "name" {
    type = string
    description = "Name of the service"
}

variable "destination_ip" {
    type = string
    description = "IP address of main destination for the service"
}

variable "base_network" {
    type = object({
        name = string
        base_cidr_block = string
        id = string
    })
    description = "Base network characteristics"
}