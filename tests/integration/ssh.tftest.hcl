# Integration tests against the throwaway SSH servers that run.sh starts in
# podman. Run them with `just test-integration`, not directly: run.sh sets the
# TF_VAR_* connection variables and removes the containers afterwards.
#
# All runs share one state, so every run replaces the resource and runs its
# script. A failing script fails the run, which is how the remote side is
# checked.

variables {
  script_location = "./tests/fixtures/write-marker.sh"
  script_content  = null
  ssh_user        = "tester"
}

run "runs_a_script_file_with_arguments" {
  variables {
    script_arguments = "'hello world'"
  }

  assert {
    condition     = output.script_hash == filemd5("./tests/fixtures/write-marker.sh")
    error_message = "script_hash must be the MD5 of the uploaded script."
  }
}

run "the_script_ran_as_the_ssh_user" {
  variables {
    script_location = null
    script_content  = <<-EOT
      #!/bin/sh
      set -eu
      [ "$(cat /tmp/marker)" = "hello world" ]
      [ "$(stat -c %U /tmp/marker)" = tester ]
    EOT
  }
}

run "use_sudo_runs_as_root" {
  variables {
    script_location = null
    use_sudo        = true
    script_content  = <<-EOT
      #!/bin/sh
      [ "$(id -u)" -eq 0 ]
    EOT
  }
}

run "interpreter_works_on_a_noexec_directory" {
  variables {
    script_location  = null
    interpreter      = "bash"
    remote_directory = "/scratch"
    # No shebang and /scratch is mounted noexec: only the interpreter can run it.
    script_content = <<-EOT
      [ -n "$BASH_VERSION" ] || exit 3
    EOT
  }
}

run "uploaded_files_are_removed" {
  variables {
    script_location = null
    script_name     = "cleanup-check.sh"
    script_content  = <<-EOT
      #!/bin/sh
      set -eu
      # The previous run used /scratch; this script is the only file in /tmp.
      [ -z "$(ls -A /scratch)" ]
      [ "$(ls -d /tmp/terraform-ssh-executor-* | wc -l)" -eq 1 ]
      ls /tmp/terraform-ssh-executor-*-cleanup-check.sh
    EOT
  }
}

run "connects_through_a_bastion" {
  variables {
    # "target" only resolves inside the podman network, so this can only work
    # through the bastion. The bastion is another container without the marker.
    ssh_host        = "target"
    ssh_port        = "22"
    bastion_host    = "127.0.0.1"
    script_location = null
    script_content  = <<-EOT
      #!/bin/sh
      [ "$(cat /tmp/marker)" = "hello world" ]
    EOT
  }
}
