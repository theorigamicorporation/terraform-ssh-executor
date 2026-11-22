# Tasks

## 1. Module

- [x] 1.1 Remove `locals.tf`, `context.tf` and the template examples
- [x] 1.2 One-line run command with exit code passthrough and cleanup on failure
- [x] 1.3 Per-run upload name and `remote_directory`
- [x] 1.4 `script_content`, `script_name`, `use_sudo`, `interpreter`
- [x] 1.5 `ssh_password`, `ssh_host_key`, `bastion_*`; optional `ssh_private_key`
- [x] 1.6 Validations and preconditions
- [x] 1.7 Outputs `id`, `script_hash`, `last_hash`
- [x] 1.8 Keep the 1.0.0 triggers for default settings

## 2. Tests

- [x] 2.1 Plan-only unit tests for triggers and validation
- [x] 2.2 Podman SSH target and bastion, `run.sh`
- [x] 2.3 Integration tests: arguments, user, sudo, interpreter on `noexec`, cleanup, bastion
- [x] 2.4 Failing script, wrong host key, upgrade from a legacy copy

## 3. Repository

- [x] 3.1 justfile, `.tool-versions`, `.tflint.hcl`, `.terraform-docs.yml`
- [x] 3.2 CI, CodeQL, Scorecard and release workflows with a shared setup action
- [x] 3.3 README, CHANGELOG, CONTRIBUTING, SECURITY, templates, logo
- [x] 3.4 Simple and complete examples
