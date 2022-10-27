# Launch a new Aviatrix controller instance and initialize
# Configure a Spoke-GW with Aviatrix Transit solution

data "aws_caller_identity" "current" {}

locals {
  # Proper boolean usage
  new_vpc = (var.controller_vpc_id == "" || var.controller_subnet_id == "" ? true : false)
  new_key = (var.keypair_name == "" ? true : false)
}


# Create AWS VPC for Aviatrix Controller
resource "aws_vpc" "controller" {
  count            = (local.new_vpc ? 1 : 0)
  cidr_block       = "10.55.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "${var.testbed_name} Controller VPC"
  }
}

# Create AWS Subnet for Aviatrix Controller
resource "aws_subnet" "controller" {
  count      = (local.new_vpc ? 1 : 0)
  vpc_id     = aws_vpc.controller[0].id
  cidr_block = "10.55.1.0/24"

  tags = {
    Name = "${var.testbed_name} Controller Subnet"
  }
  depends_on = [
    aws_vpc.controller
  ]
}

# Public-Private key generation
resource "tls_private_key" "terraform_key" {
  count     = (local.new_key ? 1 : 0)
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "cloud_pem" {
  count     = (local.new_key ? 1 : 0)
  filename        = "cloudtls.pem"
  content         = tls_private_key.terraform_key[0].private_key_pem
  file_permission = "0600"
}

resource "random_id" "key_id" {
  count     = (local.new_key ? 1 : 0)
	byte_length = 4
}

# Create AWS keypair
resource "aws_key_pair" "controller" {
  count     = (local.new_key ? 1 : 0)
  key_name   = "controller-key-${random_id.key_id[0].dec}"
  public_key = tls_private_key.terraform_key[0].public_key_openssh
}

# Build Aviatrix controller instance with new create vpc
module "aviatrix_controller_build_new_vpc" {
  count          = (local.new_vpc ? 1 : 0)
  source         = "./aviatrix_controller_build"
  vpc_id         = aws_vpc.controller[0].id
  subnet_id      = aws_subnet.controller[0].id
  keypair_name   = (local.new_key ? aws_key_pair.controller[0].key_name : var.keypair_name)
  name = "${var.testbed_name}-Controller"
  incoming_ssl_cidr = "${concat(var.incoming_ssl_cidr, [aws_vpc.controller[0].cidr_block])}"
  ssh_cidrs = var.incoming_ssl_cidr
}

#Buile Aviatrix controller at existed VPC
module "aviatrix_controller_build_existed_vpc" {
  count   = (local.new_vpc ? 0 : 1)
  source  = "git@github.com:AviatrixDev/terraform-modules-aws-internal.git//aviatrix-controller-build?ref=main"
  vpc     = var.controller_vpc_id
  subnet  = var.controller_subnet_id
  keypair = (local.new_key ? aws_key_pair.controller[0].key_name : var.keypair_name)
  ec2role = "aviatrix-role-ec2"
  type = "BYOL"
  termination_protection = false
  controller_name = "${var.testbed_name}-Controller"
  name_prefix = var.testbed_name
  root_volume_size = "64"
  incoming_ssl_cidr = "${concat(var.incoming_ssl_cidr, [var.controller_vpc_cidr])}"
  ssh_cidrs = var.incoming_ssl_cidr
}

# resource "time_sleep" "wait_210s" {
#   create_duration = "240s"
#   depends_on                    = [
#     module.aviatrix_controller_build_existed_vpc,
#     module.aviatrix_controller_build_new_vpc
#   ]
# }

#Initialize Controller GCP
module "aviatrix_controller_initialize" {
  source                              = "git@github.com:AviatrixSystems/terraform-aviatrix-gcp-controller.git//modules/aviatrix-controller-initialize?ref=main"
  avx_controller_public_ip            = local.new_vpc ? module.aviatrix_controller_build_new_vpc[0].public_ip : module.aviatrix_controller_build_existed_vpc[0].public_ip
  avx_controller_private_ip           = local.new_vpc ? module.aviatrix_controller_build_new_vpc[0].private_ip : module.aviatrix_controller_build_existed_vpc[0].private_ip
  avx_controller_admin_email          = var.aviatrix_admin_email
  avx_controller_admin_password       = var.aviatrix_controller_password
  gcloud_project_credentials_filepath = var.gcp_credentials_filepath
  access_account_name                 = var.aviatrix_access_account
  aviatrix_customer_id                = var.aviatrix_license_id
  controller_version                  = var.upgrade_target_version
  depends_on          = [
    module.aviatrix_controller_build_existed_vpc,
    module.aviatrix_controller_build_new_vpc
  ]
}

resource "aviatrix_controller_cert_domain_config" "controller_cert_domain" {
    provider    = aviatrix.new_controller
    cert_domain = var.cert_domain
    depends_on  = [
      module.aviatrix_controller_initialize
    ]
}

resource "time_sleep" "wait_60s" {
  create_duration = "60s"
  depends_on      = [
    aviatrix_controller_cert_domain_config.controller_cert_domain
  ]
}

# Create spoke VNET and end VM.
module "gcp-spoke-vnet" {
  source              = "git@github.com:AviatrixDev/automation_test_scripts.git//Regression_Testbed_TF_Module/modules/testbed-vpc-gcp?ref=master"
  // please do not use special characters such as `\/"[]:|<>+=;,?*@&~!#$%^()_{}'` in the controller_name
  vpc_count             = var.spoke_count
  resource_name_label = "${var.testbed_name}-spoke"
  pub_subnet            = var.pub_subnet1_cidr
  pri_subnet            = var.pri_subnet1_cidr
  pub_instance_zone     = ["${var.spoke_vpc_reg}-a"]
  pri_instance_zone     = ["${var.spoke_vpc_reg}-b"]
  pub_subnet_region     = var.spoke_vpc_reg
  pri_subnet_region     = var.spoke_vpc_reg
  pub_hostnum           = 20
  pri_hostnum           = 40
  ssh_user              = var.ssh_user
  public_key            = (local.new_key ? tls_private_key.terraform_key[0].public_key_openssh : file(var.public_key_path))
}

# Create a GCP VPC
resource "aviatrix_vpc" "transit" {
  provider     = aviatrix.new_controller
  account_name = var.aviatrix_access_account
  count        = (var.transit_vpc_id != "" ? 0 : 1)
  cloud_type   = 4
  name         = "${var.testbed_name}-tr-vpc"

  subnets {
    name   = "${var.testbed_name}-tr"
    region = var.transit_vpc_reg
    cidr   = "192.168.0.0/16"
  }
  depends_on  = [
    time_sleep.wait_60s
  ]
}

#Create an Aviatrix Transit Gateway in GCP
resource "aviatrix_transit_gateway" "transit" {
  provider     = aviatrix.new_controller
  cloud_type   = 4
  account_name = var.aviatrix_access_account
  gw_name      = "${var.testbed_name}-transit-gw"
  vpc_id       = (var.transit_vpc_id != "" ? var.transit_vpc_id : aviatrix_vpc.transit[0].vpc_id)
  vpc_reg      = "${var.transit_vpc_reg}-a"
  gw_size      = var.transit_gw_size
  subnet       = (var.transit_subnet_cidr != "" ? cidrsubnet(var.transit_subnet_cidr, 0, 0) : aviatrix_vpc.transit[0].subnets[0].cidr)
  ha_zone      = "${var.transit_vpc_reg}-b"
  ha_subnet    = (var.transit_subnet_cidr != "" ? cidrsubnet(var.transit_subnet_cidr, 0, 0) : aviatrix_vpc.transit[0].subnets[0].cidr)
  ha_gw_size   = var.transit_gw_size
  insane_mode  = true
  depends_on   = [
    aviatrix_vpc.transit,
    # aviatrix_spoke_gateway.spoke,
    time_sleep.wait_60s
  ]
}

# Create an Aviatrix GCP Spoke Gateway
resource "aviatrix_spoke_gateway" "spoke" {
  provider     = aviatrix.new_controller
  count        = 1
  cloud_type   = 4
  account_name = var.aviatrix_access_account
  gw_name      = "${var.testbed_name}-spoke-gw-${count.index}"
  vpc_id       = module.gcp-spoke-vnet.vpc_name[count.index]
  vpc_reg      = "${var.spoke_vpc_reg}-a"
  gw_size      = var.spoke_gw_size
  subnet       = module.gcp-spoke-vnet.subnet_cidr[count.index]
  ha_subnet    = module.gcp-spoke-vnet.subnet_cidr[count.index]
  ha_zone      = "${var.spoke_vpc_reg}-b"
  ha_gw_size   = var.spoke_gw_size
  depends_on   = [
    module.gcp-spoke-vnet,
    time_sleep.wait_60s
  ]
}

# Create Spoke-Transit Attachment
resource "aviatrix_spoke_transit_attachment" "spoke" {
  provider        = aviatrix.new_controller
  count           = 1
  spoke_gw_name   = aviatrix_spoke_gateway.spoke[count.index].gw_name
  transit_gw_name = aviatrix_transit_gateway.transit.gw_name
}

# Aviatrix Transit Gateway Data Source
data "aviatrix_transit_gateway" "transit" {
  provider     = aviatrix.new_controller
  gw_name      = aviatrix_transit_gateway.transit.gw_name
}

# Following is CloudN Registration and Attachment.
# locals {
#   cloudn_url = "${var.cloudn_hostname}:${var.cloudn_https_port}"
# }

# #Reset CloudN
# resource "null_resource" "reset_cloudn" {
#   count = (var.enable_caag ? 1 : 0)
#   provisioner "local-exec" {
#     command = <<-EOT
#             AVTX_CID=$(curl -X POST  -k https://${local.cloudn_url}/v1/backend1 -d 'action=login_proc&username=admin&password=Aviatrix123#'| awk -F"\"" '{print $34}');
#             curl -X POST  -k https://${local.cloudn_url}/v1/api -d "action=reset_caag_to_cloudn_factory_state_by_cloudn&CID=$AVTX_CID"
#         EOT
#   }
# }

# resource "time_sleep" "wait_120_seconds" {
#   count      = (var.enable_caag ? 1 : 0)
#   depends_on = [null_resource.reset_cloudn]

#   create_duration = "120s"
# }

# # Register a CloudN to Controller
# resource "aviatrix_cloudn_registration" "cloudn_registration" {
#   provider        = aviatrix.new_controller
#   count           = (var.enable_caag ? 1 : 0)
#   name            = var.caag_name
#   username        = var.aviatrix_controller_username
#   password        = var.aviatrix_controller_password
#   address         = local.cloudn_url

#   depends_on      = [
#     time_sleep.wait_120_seconds
#   ]
# 	lifecycle {
# 		ignore_changes = all
# 	}
# }

# resource time_sleep wait_30_s{
#   create_duration = "30s"
#   depends_on = [
#     aviatrix_cloudn_registration.cloudn_registration
#   ]
# }

# # Create a CloudN Transit Gateway Attachment
# resource "aviatrix_cloudn_transit_gateway_attachment" "caag" {
#   provider                              = aviatrix.new_controller
#   count                                 = (var.enable_caag ? 1 : 0)
#   device_name                           = var.caag_name
#   transit_gateway_name                  = aviatrix_transit_gateway.transit.gw_name
#   connection_name                       = var.caag_connection_name
#   transit_gateway_bgp_asn               = var.transit_gateway_bgp_asn
#   cloudn_bgp_asn                        = var.cloudn_bgp_asn
#   cloudn_lan_interface_neighbor_ip      = var.cloudn_lan_interface_neighbor_ip
#   cloudn_lan_interface_neighbor_bgp_asn = var.cloudn_lan_interface_neighbor_bgp_asn
#   enable_over_private_network           = var.enable_over_private_network 
#   enable_jumbo_frame                    = false
#   depends_on = [
#     aviatrix_transit_gateway.transit,
#     time_sleep.wait_30_s
#   ]
# }