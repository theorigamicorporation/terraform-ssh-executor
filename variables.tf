################################################################################
# Script
################################################################################

variable "script_location" {
  type        = string
  default     = null
  description = "Path to a local script file to upload and run. Set this or `script_content`."

  validation {
    condition     = var.script_location == null ? true : (fileexists(var.script_location) && !can(regex("'", basename(var.script_location))))
    error_message = "script_location must point to an existing file whose name has no single quotes."
  }
}

variable "script_content" {
  type        = string
  default     = null
  description = "Script text to upload and run, for example the result of `templatefile()`. Set this or `script_location`. Start it with a shebang unless you set `interpreter`."
}

variable "script_name" {
  type        = string
  default     = "script.sh"
  description = "File name used on the remote host for `script_content`. Ignored with `script_location`, which keeps the local file name."

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.script_name))
    error_message = "script_name may only contain letters, digits, dots, dashes and underscores."
  }
}

variable "script_arguments" {
  type        = string
  default     = ""
  description = "Arguments appended to the script command line as they are, so quote them for the remote shell yourself. They are stored in the state."
}

variable "interpreter" {
  type        = string
  default     = null
  description = "Program that runs the script, such as `bash` or `/usr/bin/python3`. Without it the script is made executable and run through its shebang, which fails when `remote_directory` is mounted `noexec`."

  validation {
    condition     = var.interpreter == null ? true : length(trimspace(var.interpreter)) > 0
    error_message = "interpreter must not be empty; leave it null to use the shebang."
  }
}

variable "use_sudo" {
  type        = bool
  default     = false
  description = "Run the script with `sudo -n`. The SSH user needs passwordless sudo."
}

variable "remote_directory" {
  type        = string
  default     = "/tmp"
  description = "Absolute directory on the remote host the script is uploaded to. The file is removed after the run, whether the script succeeds or not."

  validation {
    condition     = can(regex("^/", var.remote_directory)) && !can(regex("'", var.remote_directory))
    error_message = "remote_directory must be an absolute path without single quotes."
  }
}

################################################################################
# When to run
################################################################################

variable "deploy_on_script_change" {
  type        = bool
  default     = true
  description = "Run the script again when its contents change. If you change this from true to false, apply once more to settle the state."
}

variable "deploy_on_every_apply" {
  type        = bool
  default     = false
  description = "Run the script on every apply. Overrides `deploy_on_script_change`. If you change this from false to true, apply once more to settle the state."
}

variable "recreate_hook" {
  type        = string
  default     = ""
  description = "Any string whose change should run the script again, such as the ID of the VM it configures or the `last_hash` output of another instance of this module."
}

variable "wait_before_deploy" {
  type        = bool
  default     = false
  description = "Sleep for `wait_seconds` on the machine running Terraform before connecting. Uses the local `sleep` command."
}

variable "wait_seconds" {
  type        = number
  default     = 0
  description = "Seconds to sleep when `wait_before_deploy` is true."

  validation {
    condition     = var.wait_seconds >= 0
    error_message = "wait_seconds must not be negative."
  }
}

################################################################################
# Connection
################################################################################

variable "ssh_host" {
  type        = string
  nullable    = false
  description = "Host name or IP address of the remote host."
}

variable "ssh_port" {
  type        = string
  default     = 22
  description = "SSH port of the remote host."

  validation {
    condition     = can(regex("^[0-9]+$", var.ssh_port)) ? (tonumber(var.ssh_port) >= 1 && tonumber(var.ssh_port) <= 65535) : false
    error_message = "ssh_port must be a number between 1 and 65535."
  }
}

variable "ssh_user" {
  type        = string
  default     = "root"
  description = "User to log in as."
}

variable "ssh_private_key" {
  type        = string
  default     = null
  sensitive   = true
  description = "Private key in OpenSSH or PEM format (the key itself, not a path; use `file()`). Not stored in the state."
}

variable "ssh_password" {
  type        = string
  default     = null
  sensitive   = true
  description = "Password to log in with when key authentication is not available. Not stored in the state."
}

variable "ssh_agent" {
  type        = bool
  default     = false
  description = "Authenticate with the keys held by the local ssh-agent (`SSH_AUTH_SOCK`)."
}

variable "ssh_host_key" {
  type        = string
  default     = null
  description = "Public host key of the remote host, or of the CA that signed it, such as `ssh-ed25519 AAAA...`. When set, the connection fails if the host presents another key. When null the host key is not checked."
}

variable "connection_timeout" {
  type        = string
  default     = "10s"
  description = "How long to keep trying to connect, as a duration such as `30s` or `5m`. Raise it when the host is still booting."

  validation {
    condition     = can(regex("^([0-9]+(\\.[0-9]+)?(ns|us|ms|s|m|h))+$", var.connection_timeout))
    error_message = "connection_timeout must be a duration such as \"10s\", \"5m\" or \"1m30s\"."
  }
}

################################################################################
# Bastion
################################################################################

variable "bastion_host" {
  type        = string
  default     = null
  description = "Jump host to connect through. `ssh_host` is then resolved and reached from the bastion."
}

variable "bastion_port" {
  type        = number
  default     = 22
  description = "SSH port of the bastion."

  validation {
    condition     = var.bastion_port >= 1 && var.bastion_port <= 65535
    error_message = "bastion_port must be between 1 and 65535."
  }
}

variable "bastion_user" {
  type        = string
  default     = null
  description = "User on the bastion. Defaults to `ssh_user`."
}

variable "bastion_private_key" {
  type        = string
  default     = null
  sensitive   = true
  description = "Private key for the bastion. Defaults to `ssh_private_key`."
}

variable "bastion_host_key" {
  type        = string
  default     = null
  description = "Public host key of the bastion, or of the CA that signed it. When null the bastion host key is not checked."
}
