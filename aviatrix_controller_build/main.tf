# Create AWS IGW for Aviatrix Controller
resource "aws_internet_gateway" "controller" {
  vpc_id = var.vpc_id

  tags = {
    Name = "IGW for Aviatrix Controller"
  }
}

# Create default IGW route
resource "aws_route_table" "public" {
  vpc_id            = var.vpc_id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.controller.id
  }

  tags = {
    Name = "Public route table for Aviatrix controller"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id        = var.subnet_id
  route_table_id   = aws_route_table.public.id
}

# Create SG for controller
resource "aws_security_group" "controller" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow SSH for debugging"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Smoke Test Controller Security Group"
  }
}

data "aws_subnet" "controller" {
  id = var.subnet_id
}

# Create EIP for controller
# resource "aws_eip" "controller" {
#   vpc                       = true
#   instance                  = aws_instance.controller.id
#   associate_with_private_ip = cidrhost(data.aws_subnet.controller.cidr_block,"101")
#   depends_on                = [aws_internet_gateway.controller]

#   tags = {
#     Name = "Smoke Test Controller EIP"
#   }
# }

# # Create Aviatrix controller instance
# resource "aws_instance" "controller" {
#   ami                         = var.controller_ami
#   instance_type               = "t2.large"
#   associate_public_ip_address = true
#   subnet_id                   = var.subnet_id
#   key_name                    = var.keypair_name
#   private_ip                  = cidrhost(data.aws_subnet.controller.cidr_block,"101")
#   vpc_security_group_ids      = [aws_security_group.controller.id]
#   iam_instance_profile        = "aviatrix-role-ec2"

#   tags = {
#     Name = "Smoke Test Controller"
#   }
# }

module "aviatrixcontroller" {
  source  = "github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-build?ref=master"
  vpc     = var.vpc_id
  subnet  = var.subnet_id
  keypair = var.keypair_name
  ec2role = "aviatrix-role-ec2"
  type = "BYOL"
  termination_protection = false
  controller_name = var.name
  root_volume_size = "64"
  incoming_ssl_cidr = var.incoming_ssl_cidr
}
