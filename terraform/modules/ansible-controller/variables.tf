variable "instance_type" {
  description = "Instance type for ansible controller"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID to launch ansible controller in"
  type        = string
}

variable "ansible_sg_id" {
  description = "Security group ID for the ansible controller"
  type        = string
}
