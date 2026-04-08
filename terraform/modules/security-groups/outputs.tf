output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "ansible_controller_sg_id" {
  value = aws_security_group.ansible_controller.id
}

output "private_sg_id" {
  value = aws_security_group.private.id
}
