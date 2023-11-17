variable "testbed_name" { default = "TFawsCaaG" }
variable "aws_region" { default = "us-west-2" }
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "gcp_credentials_filepath" {}
variable "gcp_project_id" {}
variable "gcp_region" {}

variable "aviatrix_controller_username" { default = "admin" }
variable "aviatrix_controller_password" { default = "Aviatrix123#" }
variable "aviatrix_admin_email" { default = "jchang@aviatrix.com" }
variable "aviatrix_controller_ami_id" { default = "" }
variable "aviatrix_access_account" { default = "gcp1" }
variable "aviatrix_license_id" {}
variable "upgrade_target_version" { default = "6.7-patch" }

variable "release_infra" { default = "staging" }

variable "transit_vpc_id" {
  description = "for private network, the transit vpc id"
  default = ""
}
variable "transit_vpc_reg" {
  description = "for private network, the transit vpc region"
  default = "us-west1"
}
variable "transit_vpc_cidr" {
  description = "for private network, the transit vpc cidr"
  default = ""
}
variable "transit_subnet_cidr" {
  description = "for private network, the transit subnet cidr"
  default = ""
}
variable "transit_gw_size" {
  description = "Size of the gateway instance"
  default = "n1-highcpu-4"
}
variable "spoke_vpc_reg" {
  description = "spoke vpc region"
  default = "us-central1"
}
variable "spoke_gw_size" {
  description = "Size of the gateway instance"
  default = "n1-standard-1"
}
variable "spoke_count" {
  description = "The number of spokes to create."
  default     = 1
}
variable "pub_subnet1_cidr" {
  description = "Public subnet 1 cidr"
  type        = list(string)
  default     = ["10.8.0.0/24"]
}
variable "pri_subnet1_cidr" {
  description = "Private subnet 1 cidr"
  type        = list(string)
  default     = ["10.8.2.0/24"]
}
variable "disable_pri_vpc" {
  type        = bool
  default     = false
}
variable "controller_vpc_id" {
  description = "create controller at existed vpc"
  default = ""
}
variable "controller_vpc_cidr" {
  description = "create controller at existed vpc"
  default = ""
}
variable "controller_subnet_id" {
  description = "create controller at existed vpc"
  default = ""
}
variable "keypair_name" {
  description = "use the key saved on aws"
  default = ""
}
variable "public_key_path" {
  type        = string
  description = "The path of public key"
  default     = ""
}
variable "incoming_ssl_cidrs" {
  type        = list(string)
  description = "The CIDR to be allowed for HTTPS(port 443) access to the controller. Type is \"list\"."
  default = [ "0.0.0.0/0" ]
}

variable "ssh_user" {
  default = "ubuntu"
}

variable "github_token" {
  description = "github oAthu token"
  type        = string
  default = ""
}
variable "cloudn_public_ip_cidr" {
  description = "CloudN public cide for controller incoming ssl"
  type        = string
  default = ""
}
variable "cloudn_hostname" {
  description = "CloudN hostname, ex:IP, or hostname"
  type        = string
  default = ""
}
variable "cloudn_https_port" {
  description = "CloudN hostname, ex:IP, or hostname"
  type        = string
  default = "22"
}
variable "cloudn_bgp_asn" {
  description = "CloudN BGP AS Number"
  type        = string
  default = ""
}
variable "cloudn_lan_interface_neighbor_ip" {
  description = "CloudN LAN Interface Neighbor's IP Address."
  type        = string
  default = ""
}
variable "cloudn_lan_interface_neighbor_bgp_asn" {
  description = "CloudN LAN Interface Neighbor's AS Number."
  type        = string
  default = ""
}
variable "transit_gateway_bgp_asn" {
  description = "The transit gw BGP ASN number"
  type        = string
  default = "65001"
}
variable "enable_caag" {
  description = "Decide register & attach the caag in this testbed"
  type        = bool
  default = false
}
variable "caag_name" {
  description = "CloudN As Gateway Name"
  type        = string
  default = "caag"
}
variable "caag_connection_name" {
  description = "CloudN As Gateway Name"
  type        = string
  default = "connection-1"
}
variable "on_prem" {
  description = " On-prem IP address"
  type        = string
  default = ""
}
variable "enable_over_private_network" {
  type       = bool
  default = false
}
variable "vcn_restore_snapshot_name" {
  type       = string
  default = ""
}
variable "cert_domain" {
  type       = string
  default = "caag.com"
}