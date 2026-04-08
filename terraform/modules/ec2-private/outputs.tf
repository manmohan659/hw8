output "ubuntu_instance_ids" {
  value = aws_instance.ubuntu[*].id
}

output "ubuntu_private_ips" {
  value = aws_instance.ubuntu[*].private_ip
}

output "amazon_linux_instance_ids" {
  value = aws_instance.amazon_linux[*].id
}

output "amazon_linux_private_ips" {
  value = aws_instance.amazon_linux[*].private_ip
}
