locals {
  option = format("%s/aviatrix_controller_init.py",
    path.module
  )
  argument = format("'%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s'",
    var.controller_launch_wait_time, var.aws_account_id, var.public_ip, var.private_ip, var.admin_email,
    var.admin_password, var.account_email, var.controller_version, local.access_account_name,
    var.customer_license_id, local.ec2_role_name, local.app_role_name, local.aws_partition
  )
}
resource "null_resource" "run_script" {
  provisioner "local-exec" {
    command = "python3 -W ignore ${local.option} ${local.argument}"
  }
}
