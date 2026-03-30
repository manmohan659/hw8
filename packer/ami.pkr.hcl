packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "ssh_public_key" {
  type    = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzbeqDRFCar0cKeMCz7pp+FknFT+dmTv1NiB3JJMUTO manmohan659@gmail.com"
}

variable "aws_profile" {
  type    = string
  default = "account2"
}

source "amazon-ebs" "amazon_linux" {
  ami_name      = "custom-amazon-linux-docker-{{timestamp}}"
  instance_type = "t3.micro"
  region        = var.aws_region
  profile       = var.aws_profile

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  ssh_username = "ec2-user"

  tags = {
    Name        = "Custom Amazon Linux with Docker"
    Builder     = "Packer"
    Environment = "DevOps-Final"
  }
}

build {
  sources = ["source.amazon-ebs.amazon_linux"]

  provisioner "shell" {
    environment_vars = [
      "SSH_PUBLIC_KEY=${var.ssh_public_key}"
    ]
    script = "scripts/setup.sh"
  }
}
