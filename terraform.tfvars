testbed_name = "caag-gcp-67tf"

# When region is changed, make sure AMI image is also changed.
aws_region     = "us-west-2"

#Use exsiting screct key for all testbed items SSH login.
keypair_name = "apitest"
public_key_path = "/Users/Chris/.ssh/apitest.pub"

# if user want to create controller at existng VPC, you need to fill enable following parameters
controller_vpc_id = "vpc-04d7383a3b654c4ec"
controller_subnet_id = "subnet-022278683e6b46764"
controller_vpc_cidr  = "10.109.0.0/16"

#controller will be upgraded to the particular version of you assign
upgrade_target_version = "6.7-patch"
# incoming_ssl_cidr = ["0.0.0.0/0"]

# if user want to create transit gw at existng VPC, you need to fill & enable following parameters
transit_vpc_id = "vpc-transit-west1-ky"
transit_vpc_reg = "us-west1"
transit_subnet_cidr = "10.50.0.0/16"


# enable_caag = false
# cloudn_hostname = "67.207.111.163"
# cloudn_https_port = "64544"
# caag_name = "vcloudn-144-awx-dx"
# cloudn_bgp_asn = "65044"
# cloudn_lan_interface_neighbor_ip = "10.210.34.100"
# cloudn_lan_interface_neighbor_bgp_asn = "65219"
# caag_connection_name = "vCN-144-apitest"
