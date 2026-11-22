# Modernize the module and bring the repository to the provider's level

## Why

The published 1.0.0 does not validate: it ships template files (`locals.tf`,
`context.tf`) that reference an undeclared `module.this`, and its examples
pass variables the module does not have. The copies of the module that live
in other repositories work, but they hide script failures (the exit code of
the final `rm` is reported) or leave the script on the host when it fails,
and they cannot use a bastion, sudo, host key checks or a rendered script.
The repository itself has no tests, no CI beyond reusable template workflows,
and a README with TODO placeholders, while the EdgeOS provider next to it has
a full set of docs, CI, security policy and specs.

## What changes

- Remove the template leftovers so the module validates.
- Run the script in one shell command that removes the file and exits with
  the script's exit code; upload it under a per-run name in a configurable
  directory.
- Add `script_content`/`script_name`, `use_sudo`, `interpreter`,
  `remote_directory`, `ssh_password`, `ssh_host_key` and the `bastion_*`
  inputs; make `script_location` and `ssh_private_key` optional; add
  validation and preconditions; add the `id`, `script_hash` and `last_hash`
  outputs.
- Keep `null_resource` and the trigger keys and values of 1.0.0 for default
  settings. New settings only become triggers when they are not default.
- Add plan-only unit tests, podman integration tests (bastion, sudo, `noexec`,
  failures, host keys, upgrade from a legacy copy), a justfile, pinned
  toolchain, CI on several Terraform and OpenTofu versions, CodeQL, Scorecard,
  tag-based releases, issue and PR templates, SECURITY.md, a rewritten README
  and CHANGELOG.

Trigger keys and values do not change for default settings, so upgrading does
not run scripts again.
