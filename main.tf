#
# Main script
#
# Author: Marc Plouhinec
#

# Alibaba Cloud provider (source: https://github.com/terraform-providers/terraform-provider-alicloud)
provider "alicloud" {}

# VPC and VSwitch
resource "alicloud_vpc" "agent_vpc" {
  name = "supervisely-agent-vpc"
  cidr_block = "192.168.0.0/16"
}
data "alicloud_zones" "az" {
  network_type = "Vpc"
  available_disk_category = "cloud_ssd"
  available_instance_type = "${var.instance_type}"
}
resource "alicloud_vswitch" "agent_vswitch" {
  name = "supervisely-agent-vswitch"
  availability_zone = "${data.alicloud_zones.az.zones.0.id}"
  cidr_block = "192.168.0.0/24"
  vpc_id = "${alicloud_vpc.agent_vpc.id}"
}

# Security groups and rules
resource "alicloud_security_group" "agent_security_group" {
  name = "supervisely-agent-security-group"
  vpc_id = "${alicloud_vpc.agent_vpc.id}"
}
resource "alicloud_security_group_rule" "accept_22_rule" {
  type = "ingress"
  ip_protocol = "tcp"
  nic_type = "intranet"
  policy = "accept"
  port_range = "22/22"
  priority = 1
  security_group_id = "${alicloud_security_group.agent_security_group.id}"
  cidr_ip = "0.0.0.0/0"
}

# Pay-as-you-go ECS instance
data "alicloud_images" "centos_images" {
  owners = "system"
  name_regex = "centos_7[a-zA-Z0-9_]+64"
  most_recent = true
}
resource "alicloud_instance" "agent_ecs" {
  instance_name = "supervisely-agent-ecs"
  description = "Supervisely agent."

  host_name = "supervisely-agent-ecs"
  password = "${var.ecs_root_password}"

  image_id = "${data.alicloud_images.centos_images.images.0.id}"
  instance_type = "${var.instance_type}"
  system_disk_category = "cloud_ssd"
  system_disk_size = 300

  internet_max_bandwidth_out = 1

  vswitch_id = "${alicloud_vswitch.agent_vswitch.id}"
  security_groups = [
    "${alicloud_security_group.agent_security_group.id}"
  ]

  provisioner "remote-exec" {
    connection {
      host = "${alicloud_instance.agent_ecs.public_ip}"
      user = "root"
      password = "${var.ecs_root_password}"
    }
    script = "install_agent.sh"
  }
}
