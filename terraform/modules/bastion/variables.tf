variable "instance_type" {
  description = "Instance type for bastion host"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID to launch bastion in"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security group ID for the bastion"
  type        = string
}
