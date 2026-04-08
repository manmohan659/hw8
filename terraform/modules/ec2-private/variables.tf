variable "instance_type" {
  description = "Instance type for private instances"
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
