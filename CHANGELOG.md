# Changelog

All notable changes are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[semantic versioning](https://semver.org/).

## Unreleased

### Added

- `script_content` and `script_name` to run a script given as text, for
  example from `templatefile()`, instead of a file.
- `use_sudo` to run the script with `sudo -n`.
- `interpreter` to run the script through a program such as `bash`, for hosts
  where the upload directory is mounted `noexec`.
- `remote_directory` to choose where the script is uploaded (default `/tmp`).
- `ssh_password` and `ssh_host_key`.
- Bastion support: `bastion_host`, `bastion_port`, `bastion_user`,
  `bastion_private_key` and `bastion_host_key`.
- Outputs `id`, `script_hash` and `last_hash`.
- Validation of ports, timeouts, the script file, the remote directory and the
  script name, and plan-time checks that exactly one script source and some
  form of authentication are set.
- Plan-only unit tests (`terraform test` / `tofu test`) and integration tests
  against SSH servers in podman, including a bastion, a `noexec` mount, a
  failing script, a wrong host key and an upgrade from the older copies of
  the module.
- CI on Terraform 1.6, 1.13 and 1.17 and OpenTofu 1.6, 1.11 and 1.13, plus
  tflint, a README drift check, CodeQL and OpenSSF Scorecard.
- `justfile`, `.tool-versions`, issue and pull request templates, a security
  policy and OpenSpec specs.

### Changed

- `script_location` and `ssh_private_key` are optional, since a script can now
  be given as text and authentication can use a password or the SSH agent.
- The script is uploaded as
  `<remote_directory>/terraform-ssh-executor-<run id>-<name>` instead of
  `/tmp/<name>`, so two instances using a script with the same name on the
  same host no longer overwrite each other.
- The `hashicorp/null` constraint is `>= 3.1.0, < 4.0.0` instead of an exact
  version, and Terraform or OpenTofu 1.6 or later is required.
- Releases are cut by pushing a `v*` tag; notes come from this file.

### Fixed

- A failing script now fails the apply. Before, the exit code of the cleanup
  command was reported, so a script that exited non-zero looked successful.
- The uploaded script is removed when the script fails, not only when it
  succeeds.
- The module validates again: 1.0.0 referenced an undeclared `module.this`
  and could not be used.

### Removed

- The unused `context.tf` / `locals.tf` template files and the template
  example variables.
- The semantic-release, pre-commit and reusable getindata workflows, replaced
  by the `justfile` and the CI workflow.

## 1.0.0 - 2024-02-28

Initial release. It does not validate; use a later version.
