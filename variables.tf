################################################################################
# Variables
################################################################################
# Version: 2.0
variable "script_location" {
  type        = string
  description = "The full path to the script including script file."
  nullable    = false
}

variable "script_arguments" {
  type        = string
  default     = ""
  description = "The arguments for the script (if any)."
}

variable "connection_timeout" {
  type        = string
  default     = "10s"
  description = "SSH timeout - default is 10s."
}

variable "ssh_port" {
  type        = string
  default     = 22
  description = "SSH port - default is 22."
}

variable "ssh_host" {
  type        = string
  description = "SSH host"
  nullable    = false
}

variable "ssh_user" {
  type        = string
  default     = "root"
  description = "SSH user - default is root."
}

variable "ssh_private_key" {
  type        = string
  description = "Private key to open a connection."
  sensitive   = true
  nullable    = false
}

variable "recreate_hook" {
  type        = string
  default     = ""
  description = "A mock parameter, you can use this and send an ID/ARN of a VM for example to trigger recreation of the module."
}

variable "deploy_on_script_change" {
  type        = bool
  description = "If true the script will be deployed if its contents are changed. Default is true. If changing from true to false, you need to re-apply."
  default     = true
}

variable "deploy_on_every_apply" {
  type        = bool
  description = "If true the script will be deployed on every apply. Default is false. This overrides the deploy_on_script_change. If changing from false to true, you need to re-apply."
  default     = false
}

variable "wait_before_deploy" {
  type        = bool
  description = "If true the script will wait for wait_seconds before deploying."
  default     = false
}

variable "wait_seconds" {
  type        = number
  description = "Seconds to wait wait before applying."
  default     = 0
}

variable "ssh_agent" {
  type        = bool
  description = "If true the ssh-agent will be used to connect to the host. Default is false."
  default     = false
}
