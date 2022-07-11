This is a terraform script is use for build a standard testbed with 1 Controller(in GCP) 1 Tr with HA, 1 Spoke with HA, 1 Spoke end VM in GCP CSP to CloudN testing 

## CloudN CaaG smoke test (GCP)

### Description

This Terraform configuration launches a new Aviatrix controller in AWS. Then, it initializes controller and installs with specific released version. It also configures 1 Spoke(HA) GWs and attaches to Transit(HA) GW in GCP

### Authenticating to Google Cloud

#### Using a Service Account 
Alternatively, a Google Cloud Service Account can be used with Terraform to authenticate. Download the JSON key file from an existing Service Account or from a newly created one. Supply the key to Terraform using the `GOOGLE_APPLICATION_CREDENTIALS` environment variable.
```shell
export GOOGLE_APPLICATION_CREDENTIALS={{path to key file}}
```
More information about using a Service Account to authenticate can be found in the Google Terraform documentation [here](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#adding-credentials).

### Prerequisites

Provide testbed info such as controller password, license etc as necessary in provider_cred.tfvars file.
> aws_access_key = "Enter_AWS_access_key"  
> aws_secret_key = "Enter_AWS_secret_key"  
> aviatrix_controller_password = "Enter_your_controller_password"  
> aviatrix_admin_email  = "Enter_your_controller_admin_email"  
> aviatrix_license_id  = "Enter_license_ID_string_for_controller"  

> gcp_project_id = ""  
> gcp_region = ""  
> gcp_credentials_filepath = ""  

Provide testbed info such as controller password, license etc as necessary in terraform.tfvars file.
```
 testbed_name = ""  
 aws_region     = "The region you want to controller and spoke deploy"  
 keypair_name = "Use exsiting screct key in AWS for SSH login controller"  
 ssh_public_key = "Adding exsiting public key to spoke end vm"
 controller_vpc_id = "Deploy the controller on existing VPC"  
 controller_subnet_id = "The subnet ID belongs to above VPC"  
 controller_vpc_cidr  = "VPC CIDR"  
 upgrade_target_version = "it will be upgraded to the particular version of you assign"  
 incoming_ssl_cidr = ["0.0.0.0/0"] If the controller is used for GCP, reserve SSL CIDR 0.0.0.0/0.

# if user want to create transit gw at existng VPC, you need to fill & enable following parameters
transit_vpc_id = ""
transit_vpc_reg = ""
transit_subnet_cidr = ""
```


### Usage for Terraform
```
terraform init
terraform apply -var-file=provider_cred.tfvars -target=module.aviatrix_controller_initialize -auto-approve && terraform apply -var-file=provider_cred.tfvars -auto-approve
terraform show
terraform destroy -var-file=provider_cred.tfvars -auto-approve
terraform show
```

