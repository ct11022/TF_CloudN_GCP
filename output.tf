output "controller_private_ip" {
  value = local.new_vpc ? module.aviatrix_controller_build_new_vpc[0].private_ip : module.aviatrix_controller_build_existed_vpc[0].private_ip
}

output "controller_public_ip" {
  value = local.new_vpc ? module.aviatrix_controller_build_new_vpc[0].public_ip : module.aviatrix_controller_build_existed_vpc[0].public_ip
}

output "transit_gw" {
  value = {
    name: aviatrix_transit_gateway.transit.gw_name,
    vpc_id: data.aviatrix_transit_gateway.transit.vpc_id
  }
}
output "spoke_gw" {
  value = {
    name: aviatrix_spoke_gateway.spoke[*].gw_name,
    vpc_id: aviatrix_spoke_gateway.spoke[*].vpc_id
  }
}
output "spoke_gw_name" {
  value = aviatrix_spoke_gateway.spoke[*].gw_name
}

output "spoke_public_vms_info" {
  value = module.gcp-spoke-vnet.ubuntu_public_vms
}

# output "spoke_private_vms_info" {
#   value = module.aws_spoke_vpc.ubuntu_private_vms[*]
# }

output "pem_filename" {
  value = (local.new_key ? local_file.cloud_pem[0].filename : null)
}
