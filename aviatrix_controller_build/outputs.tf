# Outputs for Aviatrix controller build module

output "public_ip" {
  # value = aws_eip.controller.public_ip
  value = module.aviatrixcontroller.public_ip
}

output "private_ip" {
  # value = aws_instance.controller.private_ip
  value = module.aviatrixcontroller.private_ip
}

# output "instance_id" {
#   value = aws_instance.controller.id
# }

# output "instance_state" {
#   value = aws_instance.controller.instance_state
# }
