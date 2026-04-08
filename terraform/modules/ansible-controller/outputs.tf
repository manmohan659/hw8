output "ansible_controller_public_ip" {
  value = aws_instance.ansible_controller.public_ip
}

output "ansible_controller_instance_id" {
  value = aws_instance.ansible_controller.id
}
