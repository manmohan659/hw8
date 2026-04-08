output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "ansible_controller_public_ip" {
  description = "Public IP of the Ansible controller"
  value       = module.ansible_controller.ansible_controller_public_ip
}

output "ubuntu_private_ips" {
  description = "Private IPs of Ubuntu EC2 instances"
  value       = module.ec2_private.ubuntu_private_ips
}

output "amazon_linux_private_ips" {
  description = "Private IPs of Amazon Linux EC2 instances"
  value       = module.ec2_private.amazon_linux_private_ips
}
