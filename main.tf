locals {
  inline_script = var.script_content != null
  script_name   = local.inline_script ? var.script_name : basename(coalesce(var.script_location, "unset"))

  script_text = local.inline_script ? var.script_content : (var.script_location == null ? null : file(var.script_location))
  script_hash = local.script_text == null ? null : md5(local.script_text)

  # These keys and values are the triggers of 1.0.0 and of the copies of this
  # module kept in other repositories. Keeping them identical means switching
  # to this version does not run the script again.
  base_triggers = {
    script             = local.script_name
    script_path        = local.inline_script ? null : var.script_location
    file_changed       = var.deploy_on_every_apply ? timestamp() : (var.deploy_on_script_change ? local.script_hash : null)
    script_arguments   = var.script_arguments
    connection_timeout = var.connection_timeout
    ssh_port           = var.ssh_port
    recreate_hook      = var.recreate_hook
    wait_seconds       = var.wait_seconds
    wait_before_deploy = var.wait_before_deploy
  }

  # Settings added later only become triggers when they differ from their
  # default, for the same reason.
  extra_triggers = {
    for k, v in {
      use_sudo    = var.use_sudo ? "true" : null
      interpreter = var.interpreter
    } : k => v if v != null
  }

  run_prefix = join(" ", compact([
    var.use_sudo ? "sudo -n" : "",
    var.interpreter == null ? "" : var.interpreter,
  ]))
}

resource "null_resource" "script" {
  triggers = merge(local.base_triggers, local.extra_triggers)

  lifecycle {
    precondition {
      condition     = (var.script_location == null) != (var.script_content == null)
      error_message = "Set exactly one of script_location and script_content."
    }

    precondition {
      condition     = var.ssh_private_key != null || var.ssh_password != null || var.ssh_agent
      error_message = "Set ssh_private_key or ssh_password, or enable ssh_agent."
    }
  }

  connection {
    type     = "ssh"
    host     = var.ssh_host
    port     = self.triggers.ssh_port
    user     = var.ssh_user
    timeout  = self.triggers.connection_timeout
    host_key = var.ssh_host_key

    private_key = var.ssh_private_key
    password    = var.ssh_password
    agent       = var.ssh_agent

    bastion_host        = var.bastion_host
    bastion_port        = var.bastion_port
    bastion_user        = var.bastion_user
    bastion_private_key = var.bastion_private_key
    bastion_host_key    = var.bastion_host_key
  }

  provisioner "local-exec" {
    command = self.triggers.wait_before_deploy == "true" ? "sleep ${self.triggers.wait_seconds}" : "echo 'No waiting...'"
  }

  # The resource ID in the file name keeps two instances that upload a script
  # with the same name to the same host from overwriting each other.
  provisioner "file" {
    content     = local.script_text
    destination = "${var.remote_directory}/terraform-ssh-executor-${self.id}-${self.triggers.script}"
  }

  # One command line, so the exit code of the script is what Terraform sees
  # and the file is removed even when the script fails.
  provisioner "remote-exec" {
    inline = [
      join("", [
        "f='${var.remote_directory}/terraform-ssh-executor-${self.id}-${self.triggers.script}'; ",
        "chmod 0700 \"$f\" && ${trimspace("${local.run_prefix} \"$f\" ${self.triggers.script_arguments}")}; ",
        "rc=$?; rm -f \"$f\"; exit $rc",
      ]),
    ]
  }
}
