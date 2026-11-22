# Plan-only tests: nothing connects anywhere. Run with `just test`.

variables {
  script_location = "./tests/fixtures/hello.sh"
  ssh_host        = "192.0.2.10"
  ssh_private_key = "not-a-real-key"
}

run "defaults_keep_the_1_0_triggers" {
  command = plan

  # Same keys and values as 1.0.0 and the copies of the module in other
  # repositories, so upgrading does not run anyone's script again.
  assert {
    condition = keys(null_resource.script.triggers) == sort([
      "connection_timeout", "file_changed", "recreate_hook", "script",
      "script_arguments", "script_path", "ssh_port", "wait_before_deploy",
      "wait_seconds",
    ])
    error_message = "The default triggers must keep the 1.0.0 key set."
  }

  assert {
    condition = (
      null_resource.script.triggers.script == "hello.sh" &&
      null_resource.script.triggers.script_path == "./tests/fixtures/hello.sh" &&
      null_resource.script.triggers.file_changed == filemd5("./tests/fixtures/hello.sh") &&
      null_resource.script.triggers.ssh_port == "22" &&
      null_resource.script.triggers.connection_timeout == "10s" &&
      null_resource.script.triggers.wait_seconds == "0" &&
      null_resource.script.triggers.wait_before_deploy == "false" &&
      null_resource.script.triggers.recreate_hook == "" &&
      null_resource.script.triggers.script_arguments == ""
    )
    error_message = "The default trigger values changed."
  }

  assert {
    condition     = output.script_hash == filemd5("./tests/fixtures/hello.sh")
    error_message = "script_hash must be the MD5 of the script."
  }
}

run "ignoring_script_changes" {
  command = plan

  variables {
    deploy_on_script_change = false
  }

  assert {
    condition     = null_resource.script.triggers.file_changed == null
    error_message = "file_changed must be null when script changes are ignored."
  }
}

run "new_settings_become_triggers_only_when_set" {
  command = plan

  variables {
    use_sudo         = true
    interpreter      = "bash"
    remote_directory = "/var/tmp"
    bastion_host     = "198.51.100.1"
    ssh_host_key     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleExampleExampleExampleExampleExample"
  }

  assert {
    condition     = null_resource.script.triggers.use_sudo == "true" && null_resource.script.triggers.interpreter == "bash"
    error_message = "use_sudo and interpreter must be triggers when set."
  }

  assert {
    condition     = length(null_resource.script.triggers) == 11
    error_message = "Only use_sudo and interpreter may add triggers; connection settings must not."
  }
}

run "inline_script" {
  command = plan

  variables {
    script_location = null
    script_content  = "#!/bin/sh\necho inline\n"
    script_name     = "inline.sh"
  }

  assert {
    condition = (
      null_resource.script.triggers.script == "inline.sh" &&
      null_resource.script.triggers.script_path == null &&
      null_resource.script.triggers.file_changed == md5("#!/bin/sh\necho inline\n")
    )
    error_message = "An inline script must be named by script_name and hashed by its content."
  }
}

run "needs_a_script" {
  command = plan

  variables {
    script_location = null
  }

  expect_failures = [null_resource.script]
}

run "rejects_two_scripts" {
  command = plan

  variables {
    script_content = "#!/bin/sh\ntrue\n"
  }

  expect_failures = [null_resource.script]
}

run "needs_credentials" {
  command = plan

  variables {
    ssh_private_key = null
  }

  expect_failures = [null_resource.script]
}

run "accepts_agent_or_password" {
  command = plan

  variables {
    ssh_private_key = null
    ssh_agent       = true
  }
}

run "rejects_missing_script_file" {
  command = plan

  variables {
    script_location = "./tests/fixtures/does-not-exist.sh"
  }

  expect_failures = [var.script_location]
}

run "rejects_bad_port" {
  command = plan

  variables {
    ssh_port = "70000"
  }

  expect_failures = [var.ssh_port]
}

run "rejects_bad_timeout" {
  command = plan

  variables {
    connection_timeout = "ten seconds"
  }

  expect_failures = [var.connection_timeout]
}

run "rejects_relative_remote_directory" {
  command = plan

  variables {
    remote_directory = "tmp"
  }

  expect_failures = [var.remote_directory]
}

run "rejects_negative_wait" {
  command = plan

  variables {
    wait_seconds = -1
  }

  expect_failures = [var.wait_seconds]
}

run "rejects_bad_script_name" {
  command = plan

  variables {
    script_location = null
    script_content  = "#!/bin/sh\ntrue\n"
    script_name     = "../evil.sh"
  }

  expect_failures = [var.script_name]
}
