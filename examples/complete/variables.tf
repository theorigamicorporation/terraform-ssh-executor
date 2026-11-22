variable "bastion_host" {
  type        = string
  description = "Public address of the bastion."
  default     = "203.0.113.5"
}

variable "private_key_path" {
  type        = string
  description = "Path to the SSH private key, used for the bastion and the servers."
  default     = "~/.ssh/id_ed25519"
}

variable "host_ca_key" {
  type        = string
  description = "Public key of the CA that signs the host keys of the bastion and the servers, or null to skip the check."
  default     = null
}

variable "agent_version" {
  type        = string
  description = "Agent version to install."
  default     = "1.4.2"
}

variable "environment" {
  type        = string
  description = "Environment name written to the agent config."
  default     = "staging"
}
