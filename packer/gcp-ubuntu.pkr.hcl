packer {
  required_plugins {
    googlecompute = {
      version = "~> 1.0.10"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "custom" {
  project_id                      = "lab-v1-0hw3q17w6a1y30jo-a5114"
  source_image                    = "ubuntu-2004-focal-v20220118"
  disable_default_service_account = true
  communicator                    = "ssh"
  ssh_username                    = "worker"
  zone                            = "europe-west1-b"

  image_name   = "envoy-ubuntu"
  machine_type = "e2-standard-8"
  network      = "hub"
  subnetwork   = "default"
}

build {
  sources = ["sources.googlecompute.custom"]

  provisioner "shell" {
    script = "./script.sh"
  }
}