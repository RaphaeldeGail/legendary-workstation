/**
 * # Legendary Workstation
 * 
 * This code sets up a plateform for managing a development environment in Google Cloud.
 * 
 * Along with a development server, securized networking access are provided.
 */

terraform {
  required_version = "~> 1.1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.5.0"
    }
  }
  backend "gcs" {
  }
}

provider "google" {
  region  = var.region
  project = var.project_id
}

resource "google_compute_network" "network" {
  name                            = var.core.network.name
  description                     = title(join(" ", [var.core.network.name, "core network"]))
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true
}