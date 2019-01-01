#
# Outputs
#
# Author: Marc Plouhinec
#

output "agent_ecs_public_ip" {
  value = "${alicloud_instance.agent_ecs.public_ip}"
}
