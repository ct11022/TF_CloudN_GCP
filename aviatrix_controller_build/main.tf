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

module "aviatrixcontroller" {
  source  = "git@github.com:AviatrixDev/terraform-modules-aws-internal.git//aviatrix-controller-build?ref=main"
  vpc     = var.vpc_id
  subnet  = var.subnet_id
  keypair = var.keypair_name
  ec2role = "aviatrix-role-ec2"
  type = "BYOL"
  termination_protection = false
  controller_name = var.name
  root_volume_size = "64"
  incoming_ssl_cidr = var.incoming_ssl_cidr
  ssh_cidrs = var.ssh_cidrs
}
