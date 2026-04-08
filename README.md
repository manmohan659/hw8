# AWS Infrastructure with Packer & Terraform

This project provisions a secure AWS infrastructure using **Packer** for custom AMI creation and **Terraform** for infrastructure-as-code deployment.

## Architecture

![Architecture Diagram](architecture.svg)

## What Gets Created

| Resource | Details |
|----------|---------|
| **Custom AMI** | Amazon Linux 2023 + Docker + SSH key (via Packer) |
| **VPC** | `10.0.0.0/16` with DNS support enabled |
| **Public Subnets** | 2 subnets across AZs (`10.0.1.0/24`, `10.0.2.0/24`) |
| **Private Subnets** | 2 subnets across AZs (`10.0.10.0/24`, `10.0.11.0/24`) |
| **Internet Gateway** | Attached to VPC for public subnet internet access |
| **NAT Gateway** | In public subnet for private subnet outbound internet access |
| **Bastion Host** | 1x `t3.micro` in public subnet (SSH from your IP only) |
| **Private Instances** | 6x `t3.micro` in private subnets using custom Packer AMI |
| **Security Groups** | Bastion: port 22 from your IP only; Private: port 22 from bastion SG only |

## Prerequisites

- AWS CLI configured with credentials (`aws configure`)
- [Packer](https://developer.hashicorp.com/packer/install) installed
- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- An SSH key pair (Ed25519 recommended)

### Install Packer & Terraform (macOS)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/packer
brew install hashicorp/tap/terraform
```

## Step 1: Build the Custom AMI with Packer

```bash
cd packer

# Initialize Packer plugins
packer init ami.pkr.hcl

# Validate the template
packer validate ami.pkr.hcl

# Build the AMI
packer build ami.pkr.hcl
```

After the build completes, Packer outputs the AMI ID. Copy it and paste into `terraform/terraform.tfvars` as `custom_ami_id`.

## Step 2: Deploy Infrastructure with Terraform

### Initialize Terraform

```bash
cd terraform
terraform init
```

![Terraform Init](screenshots/02-terraform-init-complete.png)

### Plan and Review

```bash
terraform apply
```

Terraform shows all 24 resources it will create including VPC, subnets, route tables, NAT gateway, security groups, bastion host, and 6 private instances:

![Terraform Plan - Key Pair and Bastion](screenshots/03-terraform-plan-keypair.png)

![Terraform Plan - Summary showing 24 resources](screenshots/05-terraform-plan-summary.png)

Type `yes` to approve.

### Resources Creating

![Terraform creating all resources](screenshots/06-terraform-apply-creating.png)

### Deployment Complete

All 24 resources created successfully. Terraform outputs the bastion public IP and all 6 private instance IPs:

![Terraform Apply Complete](screenshots/07-terraform-apply-complete.png)

## Step 3: Verify in AWS Console

After deployment, all 7 instances (1 bastion + 6 private) are visible and running in the EC2 console:

![AWS Console - EC2 Instances Running](screenshots/08-aws-ec2-instances.png)

## Step 4: Connect to Private Instances via Bastion

The same SSH key is used for both bastion and private instances. Use SSH agent forwarding to hop through the bastion.

### SSH to Bastion, then hop to Private Instance

```bash
# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github

# SSH to bastion with agent forwarding
ssh -A -i ~/.ssh/id_ed25519_github ec2-user@<BASTION_PUBLIC_IP>

# From bastion, hop to any private instance
ssh ec2-user@<PRIVATE_INSTANCE_IP>

# Verify Docker
docker --version
```

![SSH into Bastion and hop to Private Instance - Docker verified](screenshots/09-ssh-bastion-hop-docker.png)

The screenshot shows:
1. SSH into the bastion host at `34.208.21.216` (Amazon Linux 2023)
2. From the bastion, SSH hop to private instance `10.0.10.46`
3. Docker version `25.0.14` confirmed on the private instance

## Cleanup

To avoid ongoing AWS charges, destroy all resources:

```bash
cd terraform
terraform destroy
```

![Terraform Destroy](screenshots/10-terraform-destroy.png)

Then optionally deregister the Packer AMI from the AWS Console (EC2 > AMIs).

---

# Assignment 11 - Terraform + Ansible

Building on the Assignment 8 infrastructure above, this update provisions **7 EC2 instances** (3 Ubuntu, 3 Amazon Linux, 1 Ansible Controller) and uses an **Ansible playbook** to configure them.

## What Changed from Assignment 8

| Change | Details |
|--------|---------|
| **EC2 Instances** | Replaced 6 identical Packer AMI instances with 3 Ubuntu + 3 Amazon Linux using dynamic AMI lookups |
| **OS Tags** | Ubuntu instances tagged `OS: ubuntu`, Amazon Linux tagged `OS: amazon` |
| **Ansible Controller** | New EC2 in public subnet with Ansible pre-installed via user_data |
| **Security Groups** | Private SG now allows SSH from both bastion and Ansible controller |
| **Ansible Playbook** | New playbook to update packages, install Docker, and report disk usage |
| **Auto-generated Inventory** | Terraform generates `ansible/inventory.ini` with correct IPs and SSH users |

## Assignment 11 Architecture

| Resource | Details |
|----------|---------|
| **VPC** | `10.0.0.0/16` with DNS support enabled |
| **Public Subnets** | 2 subnets across AZs (`10.0.1.0/24`, `10.0.2.0/24`) |
| **Private Subnets** | 2 subnets across AZs (`10.0.10.0/24`, `10.0.11.0/24`) |
| **Internet Gateway** | Attached to VPC for public subnet internet access |
| **NAT Gateway** | In public subnet for private subnet outbound internet access |
| **Bastion Host** | 1x `t3.micro` in public subnet (SSH from your IP only) |
| **Ansible Controller** | 1x `t3.micro` in public subnet (Ansible pre-installed via user_data) |
| **Ubuntu Instances** | 3x `t3.micro` in private subnets (tagged `OS: ubuntu`) |
| **Amazon Linux Instances** | 3x `t3.micro` in private subnets (tagged `OS: amazon`) |
| **Security Groups** | Bastion & Ansible Controller: SSH from your IP; Private: SSH from bastion & controller |

## Assignment 11 Prerequisites

- AWS CLI configured with credentials (`aws configure`)
- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- An SSH key pair (Ed25519 recommended)

## Step 1: Configure Variables

Edit `terraform/terraform.tfvars` with your values:

```hcl
aws_region            = "us-west-2"
aws_profile           = "account2"           # Your AWS CLI profile
my_ip                 = "YOUR_PUBLIC_IP"      # Your public IP for SSH access
ssh_public_key_path   = "~/.ssh/id_ed25519_github.pub"
```

Find your public IP:

```bash
curl -s ifconfig.me
```

## Step 2: Deploy Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (creates 8 EC2 instances: 1 bastion + 1 ansible controller + 3 ubuntu + 3 amazon linux)
terraform apply
```

Type `yes` to approve. Terraform outputs the following IPs:

- `bastion_public_ip` - Public IP of the bastion host
- `ansible_controller_public_ip` - Public IP of the Ansible controller
- `ubuntu_private_ips` - Private IPs of the 3 Ubuntu instances
- `amazon_linux_private_ips` - Private IPs of the 3 Amazon Linux instances

Terraform also auto-generates the Ansible inventory file at `ansible/inventory.ini`.

## Step 3: Verify EC2 Instances in AWS Console

After deployment, verify all 8 instances are running in the EC2 console. You should see:

- 1 bastion host
- 1 Ansible controller
- 3 Ubuntu instances (tagged `OS: ubuntu`)
- 3 Amazon Linux instances (tagged `OS: amazon`)

## Step 4: Run the Ansible Playbook

### 4a. SSH into the Ansible Controller

```bash
# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github

# SSH into the Ansible controller
ssh -A ec2-user@<ANSIBLE_CONTROLLER_PUBLIC_IP>
```

### 4b. Wait for Ansible Installation

The Ansible controller installs Ansible via user_data on first boot. Verify it's ready:

```bash
ansible --version
```

If the command is not found, wait a minute and try again (user_data is still running).

### 4c. Copy Playbook and Inventory to the Controller

From your **local machine** (not the controller), SCP the files:

```bash
scp -r ansible/* ec2-user@<ANSIBLE_CONTROLLER_PUBLIC_IP>:~/
scp ~/.ssh/id_ed25519_github ec2-user@<ANSIBLE_CONTROLLER_PUBLIC_IP>:~/.ssh/
```

### 4d. Run the Playbook

SSH back into the controller and run:

```bash
ssh -A ec2-user@<ANSIBLE_CONTROLLER_PUBLIC_IP>

# Set correct permissions on the SSH key
chmod 600 ~/.ssh/id_ed25519_github

# Run the playbook
ansible-playbook -i inventory.ini playbook.yml
```

### What the Playbook Does

1. **Updates and upgrades packages** - `apt update && apt upgrade` for Ubuntu, `dnf update` for Amazon Linux
2. **Installs and verifies latest Docker** - Installs Docker from official repos and starts the service
3. **Reports disk usage** - Runs `df -h` and displays output for each instance

## Step 5: Cleanup

To avoid ongoing AWS charges, destroy all resources:

```bash
cd terraform
terraform destroy
```

Type `yes` to confirm.

## Project Structure

```
hw8/
├── ansible/
│   ├── ansible.cfg              # Ansible configuration
│   ├── inventory.ini            # Auto-generated by Terraform
│   └── playbook.yml             # Main playbook (update, Docker, disk usage)
├── packer/
│   ├── ami.pkr.hcl              # Packer template (from Assignment 8)
│   └── scripts/
│       └── setup.sh             # AMI provisioning script
├── terraform/
│   ├── main.tf                  # Root module - wires all modules + generates inventory
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values (IPs)
│   ├── terraform.tfvars         # Variable values (edit before applying)
│   ├── templates/
│   │   └── inventory.tpl        # Ansible inventory template
│   └── modules/
│       ├── vpc/                 # VPC + Internet Gateway
│       ├── subnets/             # Public + Private subnets
│       ├── routing/             # Route tables + NAT Gateway
│       ├── security-groups/     # Bastion SG + Ansible Controller SG + Private SG
│       ├── bastion/             # Bastion host EC2
│       ├── ansible-controller/  # Ansible controller EC2 (with Ansible pre-installed)
│       └── ec2-private/         # 3 Ubuntu + 3 Amazon Linux EC2 instances
├── screenshots/                 # Deployment evidence
├── .gitignore
└── README.md
```
