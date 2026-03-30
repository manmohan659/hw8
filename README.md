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
| **Bastion Host** | 1x `t4g.micro` in public subnet (SSH from your IP only) |
| **Private Instances** | 6x `t3.micro` in private subnets using custom Packer AMI |
| **Security Groups** | Bastion: port 22 from your IP only; Private: port 22 from bastion SG only |

## Prerequisites

- AWS CLI configured with credentials (`aws configure`)
- [Packer](https://developer.hashicorp.com/packer/install) installed
- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- An existing AWS Key Pair named `manmohan` in `us-west-2`
- Sufficient vCPU quota (at least 16 for all 7 instances + headroom). Check with:
  ```bash
  aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A --region us-west-2
  ```

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

After the build completes, Packer outputs the AMI ID:
```
==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs.amazon_linux: AMIs were created:
us-west-2: ami-0fb6ab17921d7d113
```

**Copy the AMI ID** and paste it into `terraform/terraform.tfvars` as `custom_ami_id`.

## Step 2: Deploy Infrastructure with Terraform

```bash
cd terraform

# Update terraform.tfvars with your Packer AMI ID and your current public IP
# Find your IP: curl -s ifconfig.me

# Initialize Terraform
terraform init

# Preview the changes
terraform plan

# Deploy
terraform apply
```

Type `yes` when prompted. Terraform outputs:
```
bastion_public_ip = "54.190.159.131"
private_instance_ips = [
  "10.0.10.126",
  "10.0.11.236",
  ...
]
```

## Step 3: Connect to Private Instances via Bastion

The bastion host uses the AWS key pair (`manmohan.pem`), while private instances use the SSH public key baked into the custom AMI.

### SSH to the Bastion Host

```bash
ssh -i /path/to/manmohan.pem ec2-user@<BASTION_PUBLIC_IP>
```

### SSH to a Private Instance via ProxyCommand

Since the bastion and private instances use different keys, use `ProxyCommand`:

```bash
ssh -o "ProxyCommand ssh -i /path/to/manmohan.pem -W %h:%p ec2-user@<BASTION_PUBLIC_IP>" \
    -i ~/.ssh/id_ed25519_github \
    ec2-user@<PRIVATE_INSTANCE_IP>
```

### Verify Docker on Private Instance

Once connected to a private instance:
```bash
docker --version
# Docker version 25.0.14, build 0bab007

docker ps
```

## Screenshots

### Packer AMI Build

```
amazon-ebs.amazon_linux: output will be in this color.
==> amazon-ebs.amazon_linux: Prevalidating AMI Name: custom-amazon-linux-docker-1774744460
==> amazon-ebs.amazon_linux: Found Image ID: ami-014d82945a82dfba3
==> amazon-ebs.amazon_linux: Creating temporary keypair...
==> amazon-ebs.amazon_linux: Launching a source AWS instance...
==> amazon-ebs.amazon_linux: Instance ID: i-0cc07655cb620d679
==> amazon-ebs.amazon_linux: Connected to SSH!
==> amazon-ebs.amazon_linux: Provisioning with shell script: scripts/setup.sh
    amazon-ebs.amazon_linux: Docker version 25.0.14, build 0bab007
    amazon-ebs.amazon_linux: Setup complete: Docker installed, SSH key configured.
==> amazon-ebs.amazon_linux: Creating AMI custom-amazon-linux-docker-1774744460...
==> amazon-ebs.amazon_linux: AMI: ami-0fb6ab17921d7d113
Build 'amazon-ebs.amazon_linux' finished after 8 minutes 17 seconds.
```

### Terraform Apply Output

```
Apply complete! Resources: 23 added, 0 changed, 0 destroyed.

Outputs:
bastion_public_ip = "54.190.159.131"
private_instance_ips = [
  "10.0.10.126",
  "10.0.11.236",
]
vpc_id = "vpc-0c906473bad308dd2"
```

### SSH Bastion Connection

```
$ ssh -i manmohan.pem ec2-user@54.190.159.131
=== BASTION CONNECTED ===
Linux ip-10-0-1-252.us-west-2.compute.internal 6.12.74-98.124.amzn2023.aarch64
```

### SSH to Private Instance via Bastion

```
$ ssh -o "ProxyCommand ssh -i manmohan.pem -W %h:%p ec2-user@54.190.159.131" \
      -i ~/.ssh/id_ed25519_github ec2-user@10.0.10.126

=== PRIVATE INSTANCE 1 CONNECTED ===
Linux ip-10-0-10-126.us-west-2.compute.internal 6.1.164-196.303.amzn2023.x86_64
Docker version 25.0.14, build 0bab007
```

## Cleanup

To avoid ongoing AWS charges, destroy all resources when done:

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted. Then optionally deregister the Packer AMI from the AWS Console (EC2 > AMIs).

## Notes

- **vCPU Quota**: The default AWS account limit is 8 vCPUs for standard instances. Running all 6 private instances (`t3.micro`, 2 vCPUs each = 12) plus a bastion (2 vCPUs) requires at least 14 vCPUs. Request an increase via:
  ```bash
  aws service-quotas request-service-quota-increase \
      --service-code ec2 --quota-code L-1216C47A \
      --desired-value 32 --region us-west-2
  ```
- **Bastion uses ARM (t4g.micro)** to conserve vCPU quota (separate pool from x86 instances).
- **Region**: All resources are deployed in `us-west-2` (Oregon).

## Project Structure

```
aws-packer-terraform/
├── packer/
│   ├── ami.pkr.hcl              # Packer template for custom AMI
│   └── scripts/
│       └── setup.sh             # Provisioning script (Docker + SSH key)
├── terraform/
│   ├── main.tf                  # Root module - wires all modules together
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   ├── terraform.tfvars         # Variable values (edit before applying)
│   └── modules/
│       ├── vpc/                 # VPC + Internet Gateway
│       ├── subnets/             # Public + Private subnets
│       ├── routing/             # Route tables + NAT Gateway
│       ├── security-groups/     # Bastion SG + Private SG
│       ├── bastion/             # Bastion host EC2
│       └── ec2-private/         # 6 private EC2 instances
├── .gitignore
└── README.md
```
