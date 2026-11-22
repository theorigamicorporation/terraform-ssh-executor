# script-execution Specification

## Purpose
How the module uploads, runs and re-runs a script on a remote host over SSH.

## Requirements

### Requirement: Script source
The module SHALL take the script from exactly one of `script_location` (a local file, uploaded under its own name) and `script_content` (text, uploaded as `script_name`), and SHALL fail at plan when neither or both are set or when the file does not exist.

#### Scenario: Rendered script
- **WHEN** `script_content` is the output of `templatefile()` and `script_name` is `install.sh`
- **THEN** the host receives a file ending in `-install.sh` with that text and runs it

#### Scenario: Both sources
- **WHEN** `script_location` and `script_content` are both set
- **THEN** plan fails with "Set exactly one of script_location and script_content"

### Requirement: Run and clean up
The module SHALL upload the script to `<remote_directory>/terraform-ssh-executor-<run id>-<name>`, run it as `[sudo -n] [interpreter] <file> <script_arguments>` in one shell command, remove the file afterwards whether the script succeeds or fails, and fail the apply with the script's exit code when it is not zero.

#### Scenario: Failing script
- **WHEN** the script exits with status 7
- **THEN** the apply fails reporting status 7 and the file is no longer on the host

#### Scenario: noexec directory
- **WHEN** `remote_directory` is mounted `noexec` and `interpreter = "bash"`
- **THEN** the script runs through bash

#### Scenario: sudo
- **WHEN** `use_sudo = true` and the SSH user has passwordless sudo
- **THEN** the script runs as root

### Requirement: When the script runs again
The module SHALL run the script on create and again when the script contents (unless `deploy_on_script_change = false`), `script_arguments`, the script path or name, `recreate_hook`, `ssh_port`, `connection_timeout`, `wait_before_deploy`, `wait_seconds`, `use_sudo` or `interpreter` change, and on every apply when `deploy_on_every_apply = true`. Changes to the host, user, credentials, host keys, bastion settings or `remote_directory` SHALL NOT run it again.

#### Scenario: Plain re-apply
- **WHEN** nothing in the module block or the script changes
- **THEN** the plan is empty

### Requirement: Stable triggers
With default values for the inputs added after 1.0.0, the trigger map SHALL have exactly the keys and values of 1.0.0, and the added inputs SHALL only add trigger keys when they are not default.

#### Scenario: Switching from a legacy copy
- **WHEN** a configuration applied with a copy of the 1.0.0 module switches its `source` to this module without other changes
- **THEN** the plan shows no changes and the script does not run

### Requirement: Connection
The module SHALL connect with a private key, a password or the SSH agent (at least one required at plan), check `ssh_host_key` and `bastion_host_key` when set, connect through `bastion_host` when set, and keep keys and passwords out of the state.

#### Scenario: Wrong host key
- **WHEN** `ssh_host_key` does not match the host
- **THEN** the apply fails before anything is uploaded or run

#### Scenario: Bastion
- **WHEN** `bastion_host` is set and `ssh_host` only resolves from the bastion
- **THEN** the script runs on `ssh_host`

### Requirement: Outputs
The module SHALL output `id` (changes on every run), `script_hash` (MD5 of the script) and `last_hash` (the `file_changed` trigger, for chaining with `recreate_hook`).

#### Scenario: Chaining
- **WHEN** a second instance sets `recreate_hook` to the first instance's `id`
- **THEN** the second script runs again every time the first one runs again
