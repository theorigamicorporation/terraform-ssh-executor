# run.sh points ./module at the legacy copy first and at the repository root
# afterwards.

variable "ssh_host" { type = string }
variable "ssh_port" { type = string }
variable "ssh_user" { type = string }
variable "ssh_private_key" {
  type      = string
  sensitive = true
}

module "exec" {
  source = "./module"

  script_location         = "${path.module}/../../fixtures/hello.sh"
  script_arguments        = "--flag value"
  ssh_host                = var.ssh_host
  ssh_port                = var.ssh_port
  ssh_user                = var.ssh_user
  ssh_private_key         = var.ssh_private_key
  deploy_on_script_change = true
}
