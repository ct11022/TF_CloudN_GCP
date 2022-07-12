## Aviatrix - Terraform Modules - Aviatrix Controller Initialize Local

### Description

This Terraform module initializes a newly created Aviatrix Controller by running local Python code.

### Usage

``` terraform
module "aviatrix_controller_init" {
  source              = "github.com/AviatrixDev/terraform-modules-aws-internal.git//aviatrix-controller-initialize-local?ref=main"
  aws_account_id      = "<<< aws account id >>>"
  private_ip          = "<<< Aviatrix Controller's private IP address (initial admin password) >>>"
  public_ip           = "<<< Aviatrix Controller's public IP address >>>"
  admin_email         = "<<< the administrator email address >>>"
  admin_password      = "<<< the new administrator password >>>"
  account_email       = "<<< account email >>>"
  access_account_name = ["<<< access account name 1 >>>", "<<< access account name 2 >>>", ...]
  customer_license_id = "<<< enter the customer license id>>>" 
}
```

### Variables

- **admin_email**

  The administrator's email address. This email address will be used for password recovery as well as for notifications
  from the Controller.

- **admin_password**

  The administrator's password. The default password is the Controller's private IP addresses. It will be changed to this
  value as part of the initialization.

- **private_ip**

  The Controller's private IP address.

- **public_ip**

  The Controller's public IP address.

- **access_account_name**

  A set of access account names.

- **account_email**

  Account email address where notifications will be sent.

- **aws_account_id**

  The AWS account ID.

- **customer_license_id**

  The customer license ID, optional. Required if using a BYOL controller.
  
- **controller_version**
  
  The version to which you want initialize the Aviatrix controller.
    
- **controller_launch_wait_time**
 
  Time in second to wait for controller to be up. Default value is 210.

- **ec2_role_name**

  EC2 role name. Default value is "aviatrix-role-ec2".

- **app_role_name**

  APP role name. Default value is "aviatrix-role-app".