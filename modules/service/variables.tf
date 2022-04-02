variable "base_network" {
    type = object({
        name = string
        base_cidr_block = string
        id = string
    })
    description = "Base network characteristics"
}