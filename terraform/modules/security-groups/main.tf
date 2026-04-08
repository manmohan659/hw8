# Bastion Security Group - only allow SSH from your IP
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH from my IP only"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-bastion-sg"
  }
}

# Ansible Controller Security Group - SSH from your IP
resource "aws_security_group" "ansible_controller" {
  name        = "ansible-controller-sg"
  description = "Allow SSH from my IP only"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-ansible-controller-sg"
  }
}

# Private Instances Security Group - allow SSH from bastion and ansible controller
resource "aws_security_group" "private" {
  name        = "private-instances-sg"
  description = "Allow SSH from bastion and ansible controller"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH from bastion and ansible controller"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id, aws_security_group.ansible_controller.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-private-sg"
  }
}
