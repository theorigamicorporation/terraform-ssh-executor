module "setup" {
  source = "../.."

  script_location = "${path.module}/scripts/setup.sh"
  ssh_host        = var.host
  ssh_user        = "root"
  ssh_private_key = file(var.private_key_path)
  ssh_host_key    = var.host_key
}
