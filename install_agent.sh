#
# Installation script for the Supervisely agent ECS instance. It setups the following applications:
#   - Docker (Version 18.0)
#   - GPU Driver (CUDA 9.0)
#   - Nvidia-docker
#
# Author: Marc Plouhinec
#
#!/usr/bin/env bash

# Update the system
yum -y update

# Install the GPU driver
echo "Installing GPU driver..."
cd /tmp
wget http://us.download.nvidia.com/tesla/384.145/nvidia-diag-driver-local-repo-rhel7-384.145-1.0-1.x86_64.rpm
rpm -i /tmp/nvidia-diag-driver-local-repo-rhel7-384.145-1.0-1.x86_64.rpm
yum -y clean all
yum -y install cuda-drivers

# Install CUDA
echo "Installing CUDA..."
wget http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-9.0.176-1.x86_64.rpm
rpm -i /tmp/cuda-repo-rhel7-9.0.176-1.x86_64.rpm
yum -y clean all
yum -y install cuda-9-0

# Install Docker
echo "Installing Docker..."
yum -y install yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce
systemctl enable docker
systemctl start docker

# Install Nvidia Docker
echo "Installing Nvidia Docker..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | tee /etc/yum.repos.d/nvidia-docker.repo
yum install -y nvidia-docker2
pkill -SIGHUP dockerd
docker run --runtime=nvidia --rm nvidia/cuda:9.0-base nvidia-smi

# Restart the machine
echo "Installation finished! Restarting..."
shutdown -r +0
