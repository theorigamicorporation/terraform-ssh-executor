# Configurations that must fail. run.sh applies them and checks the error.

variable "ssh_host" { type = string }
variable "ssh_port" { type = string }
variable "ssh_user" { type = string }
variable "ssh_private_key" {
  type      = string
  sensitive = true
}
variable "ssh_host_key" { type = string }
variable "script_content" { type = string }

module "exec" {
  source = "../../.."

  script_content     = var.script_content
  script_name        = "negative.sh"
  ssh_host           = var.ssh_host
  ssh_port           = var.ssh_port
  ssh_user           = var.ssh_user
  ssh_private_key    = var.ssh_private_key
  ssh_host_key       = var.ssh_host_key
  connection_timeout = "5s"
}
