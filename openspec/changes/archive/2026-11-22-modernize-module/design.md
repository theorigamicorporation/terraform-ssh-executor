# Design

## null_resource, not terraform_data

`terraform_data` is the built-in replacement for `null_resource` and would
drop the `hashicorp/null` dependency. Both Terraform 1.16 and OpenTofu 1.12
support `moved` from `null_resource` to `terraform_data`, but both plan a
replacement after the move even when `triggers_replace` holds exactly the old
trigger map (tried with an object, `tomap()`, with and without null values).
A replacement runs the script, and these scripts install clusters and
configure hosts. The copies of the module in other repositories use
`null_resource`, so keeping it lets them switch to the registry module with no
change in the plan. A move to `terraform_data` belongs in a major release.

## Stable triggers

The trigger map of 1.0.0 is kept key for key and value for value
(`script`, `script_path`, `file_changed`, `script_arguments`,
`connection_timeout`, `ssh_port`, `recreate_hook`, `wait_seconds`,
`wait_before_deploy`). Settings added later are merged in only when they are
not default (`use_sudo = true`, `interpreter` set). Connection settings
(host keys, bastion, password, agent) and `remote_directory` are not
triggers: changing how to reach a host is not a reason to run the script
again. `ssh_host` was never a trigger and stays that way; `recreate_hook`
covers a replaced host. A unit test pins the default key set and values, and
an integration test applies a legacy copy and checks that switching plans no
changes.

## Running the script

Terraform's `remote-exec` joins inline commands into one script without
`set -e`, so the old three-command form reported the exit code of `rm`. The
run is now one command line:

    f='<dir>/terraform-ssh-executor-<id>-<name>'; chmod 0700 "$f" && [sudo -n] [interpreter] "$f" <args>; rc=$?; rm -f "$f"; exit $rc

The resource ID in the file name keeps two instances that run a script with
the same name on the same host from overwriting each other, and makes the
name hard to guess. `remote_directory` is validated as absolute and free of
single quotes because it is placed inside single quotes.

The file provisioner cannot take `source` and `content` both, even when one is
null, so the module always uploads `content`: the file is read with `file()`
or taken from `script_content`. Scripts must therefore be UTF-8 text.

## Validation

Cross-variable validation needs Terraform 1.9, so the "exactly one script"
and "some authentication" rules are preconditions on the resource, which work
from 1.2. Single-variable rules (port range, duration format, file exists,
absolute directory, script name characters, non-negative wait) are variable
validations. Conditionals stand in for short-circuit `||`, which older
versions do not have.

## Tooling

The repository follows the EdgeOS provider: `.tool-versions` is read by the
CI setup action, the justfile is the entry point, README tables are generated
and checked for drift, actions are pinned by SHA, Scorecard and CodeQL run on
`master`, and releases are tags with notes taken from CHANGELOG.md. The
integration tests use podman on GitHub-hosted runners as well as locally.
