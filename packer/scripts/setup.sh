#!/bin/bash
set -euxo pipefail

# Update system packages
sudo dnf update -y

# Install Docker
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker

# Add ec2-user to docker group so it can run docker without sudo
sudo usermod -aG docker ec2-user

# Set up SSH public key
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "${SSH_PUBLIC_KEY}" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Verify installations
docker --version
echo "Setup complete: Docker installed, SSH key configured."
