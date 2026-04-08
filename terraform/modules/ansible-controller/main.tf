# Use latest Amazon Linux 2023 for the Ansible Controller
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "ansible_controller" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.ansible_sg_id]

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y python3-pip
    pip3 install ansible
  EOF

  tags = {
    Name = "devops-ansible-controller"
  }
}
