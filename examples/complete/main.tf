# Two servers in a private network, reached through a bastion. The agent
# install is rendered from a template, runs with sudo and runs again when the
# template, its variables or the server's ID change. A report runs after it on
# every apply.

locals {
  servers = {
    app-1 = { address = "10.0.1.11", id = "srv-0001" }
    app-2 = { address = "10.0.1.12", id = "srv-0002" }
  }
}

module "install_agent" {
  source   = "../.."
  for_each = local.servers

  script_name = "install-agent.sh"
  script_content = templatefile("${path.module}/scripts/install-agent.sh.tftpl", {
    agent_version = var.agent_version
    environment   = var.environment
    server        = each.key
  })

  ssh_host        = each.value.address
  ssh_user        = "deploy"
  ssh_private_key = file(var.private_key_path)
  ssh_host_key    = var.host_ca_key
  use_sudo        = true

  # /tmp is mounted noexec on these servers.
  remote_directory = "/var/tmp"
  interpreter      = "sh"

  bastion_host     = var.bastion_host
  bastion_user     = "jump"
  bastion_host_key = var.host_ca_key

  # The servers may still be booting when they are created.
  connection_timeout = "5m"

  # Run again when the server is replaced.
  recreate_hook = each.value.id
}

module "report" {
  source   = "../.."
  for_each = local.servers

  script_location       = "${path.module}/scripts/report.sh"
  deploy_on_every_apply = true

  ssh_host        = each.value.address
  ssh_user        = "deploy"
  ssh_private_key = file(var.private_key_path)
  ssh_host_key    = var.host_ca_key
  bastion_host    = var.bastion_host
  bastion_user    = "jump"

  # Run after the install, and again whenever it runs again.
  recreate_hook = module.install_agent[each.key].id
}
