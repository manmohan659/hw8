[ubuntu]
%{ for i, ip in ubuntu_ips ~}
ubuntu-${i + 1} ansible_host=${ip}
%{ endfor ~}

[amazon]
%{ for i, ip in amazon_linux_ips ~}
amazon-${i + 1} ansible_host=${ip}
%{ endfor ~}

[ubuntu:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=${ssh_key_path}

[amazon:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=${ssh_key_path}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
