output "network" {
  value = {
    name            = google_compute_network.network.name
    base_cidr_block = var.core.network.base_cidr_block
    id              = google_compute_network.network.id
  }
  description = "Main network characteristics"
}