variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "igw_id" {
  description = "Internet Gateway ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}
