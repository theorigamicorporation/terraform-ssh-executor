# Copy of the module as it was kept in other repositories before 1.1.0
# (zone09 modules/ssh-executor-bash). run.sh applies it and then checks that
# switching to this repository's module plans no changes.
################################################################################
# Main
################################################################################
# TODO: Get the file_name from one absolute path and reduce the variables by one.
resource "null_resource" "script" {
  triggers = {
    script             = basename(var.script_location)
    script_path        = var.script_location
    file_changed       = var.deploy_on_every_apply ? timestamp() : (var.deploy_on_script_change ? md5(file(var.script_location)) : null)
    script_arguments   = var.script_arguments
    connection_timeout = var.connection_timeout
    ssh_port           = var.ssh_port
    recreate_hook      = var.recreate_hook
    wait_seconds       = var.wait_seconds
    wait_before_deploy = var.wait_before_deploy
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    host        = var.ssh_host
    port        = self.triggers.ssh_port
    timeout     = self.triggers.connection_timeout
    private_key = var.ssh_private_key
  }

  provisioner "local-exec" {
    command = self.triggers.wait_before_deploy ? "sleep ${self.triggers.wait_seconds}" : "echo 'No waiting...'"
  }

  provisioner "file" {
    on_failure  = fail
    source      = self.triggers.script_path
    destination = "/tmp/${self.triggers.script}"
  }

  provisioner "remote-exec" {
    on_failure = fail
    inline = [
      "chmod +x /tmp/${self.triggers.script} || exit 1",
      "/tmp/${self.triggers.script} ${self.triggers.script_arguments} || exit 1",
      "rm -rf /tmp/${self.triggers.script} || exit 1",
    ]
  }

}
output "last_hash" {
  value = null_resource.script.triggers.file_changed
}
