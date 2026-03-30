resource "aws_instance" "private" {
  count                  = var.instance_count
  ami                    = var.custom_ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.private_sg_id]

  tags = {
    Name = "devops-private-instance-${count.index + 1}"
  }
}
