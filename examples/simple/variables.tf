variable "host" {
  type        = string
  description = "Address of the server to configure."
  default     = "192.0.2.10"
}

variable "private_key_path" {
  type        = string
  description = "Path to the SSH private key."
  default     = "~/.ssh/id_ed25519"
}

variable "host_key" {
  type        = string
  description = "Public host key of the server (`ssh-keyscan -t ed25519 <host>`), or null to skip the check."
  default     = null
}
