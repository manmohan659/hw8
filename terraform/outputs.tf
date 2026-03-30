output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "private_instance_ips" {
  description = "Private IPs of EC2 instances in private subnets"
  value       = module.ec2_private.private_instance_private_ips
}
