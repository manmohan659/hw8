variable "instance_count" {
  description = "Number of private EC2 instances"
  type        = number
}

variable "instance_type" {
  description = "Instance type for private instances"
  type        = string
}

variable "custom_ami_id" {
  description = "Custom AMI ID from Packer"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "private_sg_id" {
  description = "Security group ID for private instances"
  type        = string
}
