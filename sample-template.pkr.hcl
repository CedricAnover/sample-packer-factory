packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}


variable "base_img_name" {
  type    = string
  default = "dock-pack-img"
}

variable "base_img_version" {
  type    = string
  default = "v0.1"
}

variable "container_name" {
  type    = string
  default = "packer-build-container"
}

variable "container_hostname" {
  type    = string
  default = "packer-build-host"
}

variable "docker_user" {
  type    = string
  default = "admin"
}

variable "golden_img_name" {
  type    = string
  default = "golden-duck"
}

variable "golden_img_version" {
  type    = string
  default = "v0.1"
}

// locals {
//   docker_exec = "docker exec -i -u ${var.docker_user} ${var.container_name} /bin/bash -c"
//   ssh_exec = "ssh ${var.docker_user}@$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' ${var.container_name}) -p 22 /bin/bash -c"
// }

source "docker" "golden-duck" {
  image = "${var.base_img_name}:${var.base_img_version}"  // Base Image
  commit = true
  pull = false  // Set to false if image exists locally
  // export_path = "./dist/packer/${var.base_img_name}-${var.base_img_version}.tar"
  discard = false
  message = "${var.base_img_name} ${var.base_img_version}"
  runtime = "sysbox-runc"
  platform = "linux/amd64"

  # Override Communicator with SSH (For Sysbox with Systemd + Docker + Sshd)
  communicator = "ssh"
  ssh_username = "${var.docker_user}"
  ssh_password = "${var.docker_user}"
  ssh_private_key_file = "./.ssh/id_rsa"

  // exec_user = "${var.docker_user}"
  fix_upload_owner = true

  run_command = [
    "-d", "-i", "-t", 
    "-p=127.0.0.1:2222:22", 
    "--name=${var.container_name}", 
    "--hostname=${var.container_hostname}", 
    "{{.Image}}"
  ]
}

build {
  name = "sysbox-builder"
  sources = ["source.docker.golden-duck"]

  # This communicates via SSH
  provisioner "shell" {
    inline = ["echo 'Hello World from Packer' >> /home/admin/hello_world.txt"]
  }

  # Create Image Name and Tag
  post-processor "docker-tag" {
    repository = "${var.golden_img_name}"  // Output Docker Image Name
    tag = ["${var.golden_img_version}"]
  }

  # Generate Tarball
  post-processor "shell-local" {
    inline = ["docker save ${var.golden_img_name}:${var.golden_img_version} | gzip > ./dist/packer/${var.golden_img_name}_${var.golden_img_version}.tar.gz"]
  }

  // Push to Docker Hub
  // https://developer.hashicorp.com/packer/integrations/hashicorp/docker/latest/components/post-processor/docker-push
  // post-processor "docker-push" {}
}
