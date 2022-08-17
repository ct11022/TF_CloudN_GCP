# Variables for Aviatrix controller build module

variable "vpc_id" {
  type        = string
  description = "VPC ID to deploy Aviatrix controller"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to launch Aviatrix controller"
}

variable "keypair_name" {
  type        = string
  description = "AWS keypair name to launch Aviatrix controller"
}

variable "name" {
  type        = string
  description = "Name of controller that will be launched"
}

variable "incoming_ssl_cidr" {
  type        = list(string)
  description = "The CIDR to be allowed for HTTPS(port 443) access to the controller. Type is \"list\"."
}
variable "ssh_cidrs" {
  type        = list(string)
  description = "The CIDR to be allowed for SSH(port 23) access to the controller. Type is \"list\"."
}
