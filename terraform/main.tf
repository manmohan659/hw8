terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# --- SSH Key Pair (created from local public key) ---
resource "aws_key_pair" "deployer" {
  key_name   = "hw8-deployer-key"
  public_key = file(var.ssh_public_key_path)
}

# --- VPC ---
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
}

# --- Subnets ---
module "subnets" {
  source               = "./modules/subnets"
  vpc_id               = module.vpc.vpc_id
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# --- Routing (IGW, NAT, Route Tables) ---
module "routing" {
  source             = "./modules/routing"
  vpc_id             = module.vpc.vpc_id
  igw_id             = module.vpc.igw_id
  public_subnet_ids  = module.subnets.public_subnet_ids
  private_subnet_ids = module.subnets.private_subnet_ids
}

# --- Security Groups ---
module "security_groups" {
  source = "./modules/security-groups"
  vpc_id = module.vpc.vpc_id
  my_ip  = var.my_ip
}

# --- Bastion Host (Public Subnet) ---
module "bastion" {
  source           = "./modules/bastion"
  instance_type    = var.bastion_instance_type
  key_name         = aws_key_pair.deployer.key_name
  public_subnet_id = module.subnets.public_subnet_ids[0]
  bastion_sg_id    = module.security_groups.bastion_sg_id
}

# --- Private EC2 Instances ---
module "ec2_private" {
  source             = "./modules/ec2-private"
  instance_count     = var.private_instance_count
  instance_type      = var.private_instance_type
  custom_ami_id      = var.custom_ami_id
  key_name           = aws_key_pair.deployer.key_name
  private_subnet_ids = module.subnets.private_subnet_ids
  private_sg_id      = module.security_groups.private_sg_id
}
