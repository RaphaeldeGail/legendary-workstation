packer {
  required_plugins {
    googlecompute = {
      version = "~> 1.0.10"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "server_key" {
  type = string
}

variable "server_cert" {
  type = string
}

source "googlecompute" "custom" {
  project_id                      = "lab-v1-0hw3q17w6a1y30jo-a5114"
  source_image                    = "ubuntu-2004-focal-v20220118"
  disable_default_service_account = true
  communicator                    = "ssh"
  ssh_username                    = "packer-bot"
  zone                            = "europe-west1-b"
  //skip_create_image               = true

  image_name        = "envoy-v{{timestamp}}-ubuntu-20"
  image_description = "Ubuntu 20.04 based VM with envoy, default configuration preinstalled."
  image_family      = "envoy-ubuntu-20"

  machine_type = "e2-standard-16"
  network      = "hub"
  subnetwork   = "default"

  disk_size = 20
  disk_type = "pd-ssd"
}

build {
  sources = ["sources.googlecompute.custom"]
  
  provisioner "shell" {
    environment_vars = [
      "SERVER_CERT=${var.server_cert}",
      "SERVER_KEY=${var.server_key}"
    ]
    script = "./envoy-script.sh"
  }
}