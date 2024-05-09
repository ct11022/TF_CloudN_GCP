# Launch a new Aviatrix controller instance and initialize
# Configure a Spoke-GW with Aviatrix Transit solution

data "aws_caller_identity" "current" {}

data "http" "icanhazip" {
  url = "http://icanhazip.com"
}

locals {
  # Proper boolean usage
  new_key                     = (var.keypair_name == "" ? true : false)
  new_incoming_ssl_cidrs      = concat(var.incoming_ssl_cidrs, ["${chomp(data.http.icanhazip.response_body)}/32"])
  iptable_ssl_cidr_jsonencode = jsonencode([for i in local.new_incoming_ssl_cidrs : { "addr" = i, "desc" = "" }])
}

# Public-Private key generation
resource "tls_private_key" "terraform_key" {
  count     = (local.new_key ? 1 : 0)
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "cloud_pem" {
  count           = (local.new_key ? 1 : 0)
  filename        = "cloudtls.pem"
  content         = tls_private_key.terraform_key[0].private_key_pem
  file_permission = "0600"
}

resource "random_id" "key_id" {
  count       = (local.new_key ? 1 : 0)
  byte_length = 4
}

# Create AWS keypair
resource "aws_key_pair" "controller" {
  count      = (local.new_key ? 1 : 0)
  key_name   = "controller-key-${random_id.key_id[0].dec}"
  public_key = tls_private_key.terraform_key[0].public_key_openssh
}

module "aviatrix_controller_build" {
  source                 = "git@github.com:AviatrixDev/terraform-aviatrix-aws-controller.git"
  create_iam_roles       = false
  use_existing_vpc       = (var.controller_vpc_id != "" ? true : false)
  vpc_id                 = var.controller_vpc_id
  subnet_id              = var.controller_subnet_id
  use_existing_keypair   = (local.new_key ? false : true)
  key_pair_name          = (local.new_key ? aws_key_pair.controller[0].key_name : var.keypair_name)
  ec2_role_name          = "aviatrix-role-ec2"
  controller_name_prefix = var.testbed_name
  allow_upgrade_jump     = true
  enable_ssh             = true
  release_infra          = var.release_infra
  ami_id                 = var.aviatrix_controller_ami_id
  incoming_ssl_cidrs     = ["0.0.0.0/0"]
  aws_account_id         = data.aws_caller_identity.current.account_id
  admin_email            = var.aviatrix_admin_email
  admin_password         = var.aviatrix_controller_password
  access_account_email   = var.aviatrix_admin_email
  access_account_name    = var.aviatrix_aws_access_account
  customer_license_id    = var.aviatrix_license_id
  controller_version     = var.upgrade_target_version
}

locals {
  controller_pub_ip = module.aviatrix_controller_build.public_ip
  controller_pri_ip = module.aviatrix_controller_build.private_ip
}

resource "aws_security_group_rule" "ingress_rule_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.new_incoming_ssl_cidrs
  security_group_id = module.aviatrix_controller_build.security_group_id
  depends_on        = [module.aviatrix_controller_build]
}

# resource "null_resource" "call_api_set_allow_list" {
#   provisioner "local-exec" {
#     command = <<-EOT
#             AVTX_CID=$(curl -X POST  -k https://${local.controller_pub_ip}/v1/backend1 -d 'action=login_proc&username=admin&password=Aviatrix123#'| awk -F"\"" '{print $34}');
#             curl -k -v -X PUT https://${local.controller_pub_ip}/v2.5/api/controller/allow-list --header "Content-Type: application/json" --header "Authorization: cid $AVTX_CID" -d '{"allow_list": ${local.iptable_ssl_cidr_jsonencode}, "enable": true, "enforce": true}'
#         EOT
#   }
#   depends_on = [
#     module.aviatrix_controller_initialize
#   ]
# }

# Create an Aviatrix GCP Account
resource "aviatrix_account" "acc_gcp" {
  provider                            = aviatrix.new_controller
  account_name                        = var.aviatrix_gcp_access_account
  cloud_type                          = 4
  gcloud_project_credentials_filepath = var.gcp_credentials_filepath
  depends_on                          = [module.aviatrix_controller_build]
}

resource "aviatrix_controller_cert_domain_config" "controller_cert_domain" {
  provider    = aviatrix.new_controller
  cert_domain = var.cert_domain
  depends_on  = [module.aviatrix_controller_build]
}

resource "time_sleep" "wait_60s" {
  create_duration = "60s"
  depends_on = [
    aviatrix_account.acc_gcp,
    aviatrix_controller_cert_domain_config.controller_cert_domain
  ]
}

# Create spoke VNET and end VM.
module "gcp-spoke-vnet" {
  source = "git@github.com:AviatrixDev/automation_test_scripts.git//Regression_Testbed_TF_Module/modules/testbed-vpc-gcp?ref=master"
  // please do not use special characters such as `\/"[]:|<>+=;,?*@&~!#$%^()_{}'` in the controller_name
  vpc_count           = var.spoke_count
  resource_name_label = "${var.testbed_name}-spoke"
  disable_pri_vpc     = var.disable_pri_vpc
  pub_subnet          = var.pub_subnet1_cidr
  pri_subnet          = var.pri_subnet1_cidr
  pub_instance_zone   = ["${var.spoke_vpc_reg}-a"]
  pri_instance_zone   = ["${var.spoke_vpc_reg}-b"]
  pub_subnet_region   = var.spoke_vpc_reg
  pri_subnet_region   = var.spoke_vpc_reg
  pub_hostnum         = 20
  pri_hostnum         = 40
  ssh_user            = var.ssh_user
  public_key          = (local.new_key ? tls_private_key.terraform_key[0].public_key_openssh : file(var.public_key_path))
}

# Create a GCP VPC
resource "aviatrix_vpc" "transit" {
  provider     = aviatrix.new_controller
  account_name = var.aviatrix_gcp_access_account
  count        = (var.transit_vpc_id != "" ? 0 : 1)
  cloud_type   = 4
  name         = "${var.testbed_name}-tr-vpc"

  subnets {
    name   = "${var.testbed_name}-tr"
    region = var.transit_vpc_reg
    cidr   = "192.168.0.0/16"
  }
  depends_on = [
    aviatrix_account.acc_gcp,
    time_sleep.wait_60s
  ]
}

#Create an Aviatrix Transit Gateway in GCP
resource "aviatrix_transit_gateway" "transit" {
  provider     = aviatrix.new_controller
  cloud_type   = 4
  account_name = var.aviatrix_gcp_access_account
  gw_name      = "${var.testbed_name}-transit-gw"
  vpc_id       = (var.transit_vpc_id != "" ? var.transit_vpc_id : aviatrix_vpc.transit[0].vpc_id)
  vpc_reg      = "${var.transit_vpc_reg}-a"
  gw_size      = var.transit_gw_size
  subnet       = (var.transit_subnet_cidr != "" ? cidrsubnet(var.transit_subnet_cidr, 0, 0) : aviatrix_vpc.transit[0].subnets[0].cidr)
  ha_zone      = "${var.transit_vpc_reg}-b"
  ha_subnet    = (var.transit_subnet_cidr != "" ? cidrsubnet(var.transit_subnet_cidr, 0, 0) : aviatrix_vpc.transit[0].subnets[0].cidr)
  ha_gw_size   = var.transit_gw_size
  insane_mode  = true
  depends_on = [
    aviatrix_account.acc_gcp,
    aviatrix_vpc.transit,
    time_sleep.wait_60s
  ]
}

# Create an Aviatrix GCP Spoke Gateway
resource "aviatrix_spoke_gateway" "spoke" {
  provider          = aviatrix.new_controller
  count             = 1
  cloud_type        = 4
  account_name      = var.aviatrix_gcp_access_account
  gw_name           = "${var.testbed_name}-spoke-${count.index}"
  vpc_id            = module.gcp-spoke-vnet.vpc_name[count.index]
  vpc_reg           = "${var.spoke_vpc_reg}-a"
  gw_size           = var.spoke_gw_size
  subnet            = module.gcp-spoke-vnet.subnet_cidr[count.index]
  manage_ha_gateway = false
  depends_on = [
    aviatrix_account.acc_gcp,
    module.gcp-spoke-vnet,
    time_sleep.wait_60s
  ]
}

# Create an Aviatrix Spoke HA Gateway
resource "aviatrix_spoke_ha_gateway" "spoke_ha" {
  provider        = aviatrix.new_controller
  count           = 1
  primary_gw_name = aviatrix_spoke_gateway.spoke[count.index].id
  gw_name         = "${var.testbed_name}-spoke-${count.index}-${var.spoke_ha_postfix_name}"
  zone            = "${var.spoke_vpc_reg}-b"
  gw_size         = var.spoke_gw_size
  subnet          = module.gcp-spoke-vnet.subnet_cidr[count.index]
}

# Create Spoke-Transit Attachment
resource "aviatrix_spoke_transit_attachment" "spoke" {
  provider        = aviatrix.new_controller
  count           = 1
  spoke_gw_name   = aviatrix_spoke_gateway.spoke[count.index].gw_name
  transit_gw_name = aviatrix_transit_gateway.transit.gw_name
  depends_on = [
    aviatrix_spoke_ha_gateway.spoke_ha
  ]
}

# Aviatrix Transit Gateway Data Source
data "aviatrix_transit_gateway" "transit" {
  provider = aviatrix.new_controller
  gw_name  = aviatrix_transit_gateway.transit.gw_name
}

