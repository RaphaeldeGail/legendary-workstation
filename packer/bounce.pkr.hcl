packer {
  required_plugins {
    googlecompute = {
      version = "~> 1.0.10"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "rsa_key" {
  type = string
}

variable "rsa_pub" {
  type = string
}

source "googlecompute" "custom" {
  project_id                      = "lab-v1-0hw3q17w6a1y30jo-a5114"
  source_image                    = "ubuntu-2004-focal-v20220118"
  disable_default_service_account = true
  communicator                    = "ssh"
  ssh_username                    = "worker"
  zone                            = "europe-west1-b"
  //skip_create_image               = true

  image_name        = "bounce-v{{timestamp}}-ubuntu-20"
  image_description = "Ubuntu 20.04 based VM with custom SSH settings for bounce."
  image_family      = "bounce-ubuntu-20"

  machine_type = "e2-micro"
  network      = "hub"
  subnetwork   = "default"

  disk_size = 10
  disk_type = "pd-standard"
}

build {
  sources = ["sources.googlecompute.custom"]

  provisioner "shell" {
    environment_vars = [
      "RSA_PUB=${var.rsa_pub}",
      "RSA_KEY=${var.rsa_key}"
    ]
    script = "./bounce-script.sh"
  }
}