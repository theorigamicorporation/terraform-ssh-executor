<div align="center">

<img src="assets/logo.svg" alt="" width="112" height="112">

# SSH executor module for Terraform and OpenTofu

**Upload a script to a server over SSH, run it, and run it again only when the script or its inputs change.**

<p>
<a href="https://github.com/theorigamicorporation/terraform-ssh-executor/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/theorigamicorporation/terraform-ssh-executor/ci.yml?style=flat-square&branch=master&label=CI"></a>
<a href="https://github.com/theorigamicorporation/terraform-ssh-executor/actions/workflows/release.yml"><img alt="Release workflow" src="https://img.shields.io/github/actions/workflow/status/theorigamicorporation/terraform-ssh-executor/release.yml?style=flat-square&label=release"></a>
<a href="https://github.com/theorigamicorporation/terraform-ssh-executor/actions/workflows/codeql.yml"><img alt="CodeQL" src="https://img.shields.io/github/actions/workflow/status/theorigamicorporation/terraform-ssh-executor/codeql.yml?style=flat-square&branch=master&label=CodeQL"></a>
<a href="https://scorecard.dev/viewer/?uri=github.com/theorigamicorporation/terraform-ssh-executor"><img alt="OpenSSF Scorecard" src="https://img.shields.io/ossf-scorecard/github.com/theorigamicorporation/terraform-ssh-executor?style=flat-square&label=OpenSSF%20Scorecard"></a>
<a href=".tflint.hcl"><img alt="tflint" src="https://img.shields.io/badge/linted%20with-tflint-5C4EE5?style=flat-square"></a>
</p>
<p>
<a href="https://github.com/theorigamicorporation/terraform-ssh-executor/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/theorigamicorporation/terraform-ssh-executor?style=flat-square&sort=semver"></a>
<a href="https://github.com/theorigamicorporation/terraform-ssh-executor/releases/latest"><img alt="Release date" src="https://img.shields.io/github/release-date/theorigamicorporation/terraform-ssh-executor?style=flat-square"></a>
</p>
<p>
<a href="https://registry.terraform.io/modules/theorigamicorporation/executor/ssh/latest"><img alt="Terraform Registry" src="https://img.shields.io/badge/Terraform-Registry-7B42BC?style=flat-square&logo=terraform&logoColor=white"></a>
<a href="https://search.opentofu.org/module/theorigamicorporation/executor/ssh/latest"><img alt="OpenTofu Registry" src="https://img.shields.io/badge/OpenTofu-Registry-FFDA18?style=flat-square&logo=opentofu&logoColor=black"></a>
</p>
<p>
<a href="LICENSE"><img alt="License Apache-2.0" src="https://img.shields.io/github/license/theorigamicorporation/terraform-ssh-executor?style=flat-square"></a>
<a href=".github/workflows/ci.yml"><img alt="Terraform >= 1.6" src="https://img.shields.io/badge/Terraform-%3E%3D%201.6-7B42BC?style=flat-square"></a>
<a href=".github/workflows/ci.yml"><img alt="OpenTofu >= 1.6" src="https://img.shields.io/badge/OpenTofu-%3E%3D%201.6-FFDA18?style=flat-square"></a>
<a href="https://github.com/theorigamicorporation/terraform-ssh-executor/commits/master"><img alt="Last commit" src="https://img.shields.io/github/last-commit/theorigamicorporation/terraform-ssh-executor?style=flat-square"></a>
<a href="https://github.com/theorigamicorporation/terraform-ssh-executor/issues"><img alt="Open issues" src="https://img.shields.io/github/issues/theorigamicorporation/terraform-ssh-executor?style=flat-square"></a>
<a href="CONTRIBUTING.md"><img alt="PRs welcome" src="https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square"></a>
</p>

</div>

## Contents

- [Features](#features)
- [Install](#install)
- [Quick start](#quick-start)
- [When the script runs](#when-the-script-runs)
- [How a run works](#how-a-run-works)
- [Requirements on the remote host](#requirements-on-the-remote-host)
- [Inputs and outputs](#inputs-and-outputs)
- [Upgrading](#upgrading)
- [Compatibility](#compatibility)
- [Limitations](#limitations)
- [FAQ](#faq)
- [Development](#development)
- [Contributing and security](#contributing-and-security)

## Features

- **Runs once, then only on change.** The script runs on create and again
  when its contents, arguments, connection port or a hook value change.
  Nothing happens on a plain re-apply.
- **A script file or a rendered template.** Point `script_location` at a file,
  or pass `script_content`, for example the output of `templatefile()`.
- **Failures fail the apply.** The exit code of the script is what Terraform
  sees, and the uploaded file is removed whether the script succeeds or not.
- **Host key checking.** Pin the host key of the server and of the bastion, or
  the CA key that signs them.
- **Bastions, sudo and `noexec` mounts.** Connect through a jump host, run the
  script with `sudo -n`, and run it through an interpreter where `/tmp` is
  mounted `noexec`.
- **Secrets stay out of the state.** Private keys and passwords are only used
  for the connection and are never written to the state.
- **Drop-in for the older copies.** With default settings the triggers are the
  same as in 1.0.0, so switching to this version does not run anyone's script
  again.
- **One module for Terraform and OpenTofu**, tested in CI against real SSH
  servers with several versions of each.

## Install

<table>
<tr><th>Terraform</th><th>OpenTofu</th></tr>
<tr>
<td>

```hcl
module "setup" {
  source  = "theorigamicorporation/executor/ssh"
  version = "~> 1.1"
  # ...
}
```

```sh
terraform init
```

</td>
<td>

```hcl
module "setup" {
  source  = "theorigamicorporation/executor/ssh"
  version = "~> 1.1"
  # ...
}
```

```sh
tofu init
```

</td>
</tr>
</table>

The block is identical. Terraform resolves the address against
`registry.terraform.io`, OpenTofu against `registry.opentofu.org`, and both
download the same tagged release from GitHub. Without a registry, use the Git
source with a tag:
`source = "git::https://github.com/theorigamicorporation/terraform-ssh-executor.git?ref=v1.1.0"`.

## Quick start

Run a script on a new server once it is up:

```hcl
module "setup" {
  source  = "theorigamicorporation/executor/ssh"
  version = "~> 1.1"

  script_location = "${path.module}/scripts/setup.sh"
  ssh_host        = "192.0.2.10"
  ssh_user        = "root"
  ssh_private_key = file("~/.ssh/id_ed25519")
  ssh_host_key    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..." # ssh-keyscan -t ed25519 192.0.2.10

  # The server may still be booting when Terraform gets here.
  connection_timeout = "5m"
}
```

Run `terraform plan` or `tofu plan`, then apply. The script's output shows up
in the apply log.

<details>
<summary><b>A rendered script, with sudo and arguments</b></summary>

```hcl
module "install_agent" {
  source  = "theorigamicorporation/executor/ssh"
  version = "~> 1.1"

  script_name = "install-agent.sh"
  script_content = templatefile("${path.module}/install-agent.sh.tftpl", {
    version = "1.4.2"
  })
  script_arguments = "--environment 'staging'"

  ssh_host        = "192.0.2.10"
  ssh_user        = "deploy"
  ssh_private_key = file("~/.ssh/id_ed25519")
  use_sudo        = true
}
```

`script_arguments` is appended to the command line as it is, so quote values
for the remote shell yourself.

</details>

<details>
<summary><b>Through a bastion, on a host where /tmp is noexec</b></summary>

```hcl
module "setup" {
  source  = "theorigamicorporation/executor/ssh"
  version = "~> 1.1"

  script_location = "${path.module}/scripts/setup.sh"

  ssh_host        = "10.0.1.11" # resolved and reached from the bastion
  ssh_user        = "deploy"
  ssh_private_key = file("~/.ssh/id_ed25519")
  ssh_host_key    = var.host_ca_key

  bastion_host     = "203.0.113.5"
  bastion_user     = "jump" # defaults to ssh_user
  bastion_host_key = var.host_ca_key

  remote_directory = "/var/tmp"
  interpreter      = "bash"
}
```

</details>

<details>
<summary><b>On every server, re-run when a server is replaced, then chain a second script</b></summary>

```hcl
module "base" {
  source   = "theorigamicorporation/executor/ssh"
  version  = "~> 1.1"
  for_each = var.servers # map of name => { address, id }

  script_location = "${path.module}/scripts/base.sh"
  ssh_host        = each.value.address
  ssh_private_key = file("~/.ssh/id_ed25519")
  recreate_hook   = each.value.id
}

module "app" {
  source   = "theorigamicorporation/executor/ssh"
  version  = "~> 1.1"
  for_each = var.servers

  script_location = "${path.module}/scripts/app.sh"
  ssh_host        = each.value.address
  ssh_private_key = file("~/.ssh/id_ed25519")

  # Runs after base, and again every time base runs again.
  recreate_hook = module.base[each.key].id
}
```

</details>

Both examples are in [`examples/`](examples): [simple](examples/simple) and
[complete](examples/complete).

## When the script runs

The script runs when the module instance is created, and again when one of
these changes:

| Change | Runs again |
|---|---|
| Script contents (file or `script_content`) | yes, unless `deploy_on_script_change = false` |
| `script_arguments`, `script_location` or the script file name | yes |
| `recreate_hook` | yes |
| `ssh_port`, `connection_timeout`, `wait_before_deploy`, `wait_seconds` | yes |
| `use_sudo`, `interpreter` | yes |
| `deploy_on_every_apply = true` | on every apply |
| `ssh_host`, `ssh_user`, keys, host keys, bastion settings, `remote_directory` | no |

`ssh_host` is not a trigger, so moving a server to a new address does not run
the script again. Pass something that identifies the server, such as its
resource ID, to `recreate_hook` if a new server should get the script.

Destroying the module does nothing on the server; it only forgets the run.

## How a run works

1. Optionally sleeps `wait_seconds` on the machine running Terraform.
2. Connects over SSH, through the bastion if one is set, and checks the host
   keys if they are set. Keeps retrying for `connection_timeout`.
3. Uploads the script with `scp` to
   `<remote_directory>/terraform-ssh-executor-<run id>-<script name>`. The run
   ID keeps two module instances that use a script with the same name on the
   same host apart.
4. Makes it executable (`0700`) and runs
   `[sudo -n] [interpreter] <file> <script_arguments>` in one shell command.
5. Removes the file, then exits with the exit code of the script. A non-zero
   exit code fails the apply, and the next apply runs the script again.

## Requirements on the remote host

- An SSH server and a POSIX shell (`sh`), with `chmod` and `rm`.
- `scp` on the remote host. Terraform's file provisioner uploads with it; on
  Alpine it is in `openssh-client-default`, on most other distributions it
  comes with the SSH client or server packages.
- Write access to `remote_directory` (default `/tmp`). If that directory is
  mounted `noexec`, set `interpreter`.
- Passwordless sudo for the SSH user if `use_sudo = true`.

## Inputs and outputs

Generated by `just docs` from the variable and output descriptions.

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0, < 4.0.0 |

### Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.1.0, < 4.0.0 |

### Resources

| Name | Type |
| ---- | ---- |
| [null_resource.script](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ssh_host"></a> [ssh\_host](#input\_ssh\_host) | Host name or IP address of the remote host. | `string` | n/a | yes |
| <a name="input_bastion_host"></a> [bastion\_host](#input\_bastion\_host) | Jump host to connect through. `ssh_host` is then resolved and reached from the bastion. | `string` | `null` | no |
| <a name="input_bastion_host_key"></a> [bastion\_host\_key](#input\_bastion\_host\_key) | Public host key of the bastion, or of the CA that signed it. When null the bastion host key is not checked. | `string` | `null` | no |
| <a name="input_bastion_port"></a> [bastion\_port](#input\_bastion\_port) | SSH port of the bastion. | `number` | `22` | no |
| <a name="input_bastion_private_key"></a> [bastion\_private\_key](#input\_bastion\_private\_key) | Private key for the bastion. Defaults to `ssh_private_key`. | `string` | `null` | no |
| <a name="input_bastion_user"></a> [bastion\_user](#input\_bastion\_user) | User on the bastion. Defaults to `ssh_user`. | `string` | `null` | no |
| <a name="input_connection_timeout"></a> [connection\_timeout](#input\_connection\_timeout) | How long to keep trying to connect, as a duration such as `30s` or `5m`. Raise it when the host is still booting. | `string` | `"10s"` | no |
| <a name="input_deploy_on_every_apply"></a> [deploy\_on\_every\_apply](#input\_deploy\_on\_every\_apply) | Run the script on every apply. Overrides `deploy_on_script_change`. If you change this from false to true, apply once more to settle the state. | `bool` | `false` | no |
| <a name="input_deploy_on_script_change"></a> [deploy\_on\_script\_change](#input\_deploy\_on\_script\_change) | Run the script again when its contents change. If you change this from true to false, apply once more to settle the state. | `bool` | `true` | no |
| <a name="input_interpreter"></a> [interpreter](#input\_interpreter) | Program that runs the script, such as `bash` or `/usr/bin/python3`. Without it the script is made executable and run through its shebang, which fails when `remote_directory` is mounted `noexec`. | `string` | `null` | no |
| <a name="input_recreate_hook"></a> [recreate\_hook](#input\_recreate\_hook) | Any string whose change should run the script again, such as the ID of the VM it configures or the `last_hash` output of another instance of this module. | `string` | `""` | no |
| <a name="input_remote_directory"></a> [remote\_directory](#input\_remote\_directory) | Absolute directory on the remote host the script is uploaded to. The file is removed after the run, whether the script succeeds or not. | `string` | `"/tmp"` | no |
| <a name="input_script_arguments"></a> [script\_arguments](#input\_script\_arguments) | Arguments appended to the script command line as they are, so quote them for the remote shell yourself. They are stored in the state. | `string` | `""` | no |
| <a name="input_script_content"></a> [script\_content](#input\_script\_content) | Script text to upload and run, for example the result of `templatefile()`. Set this or `script_location`. Start it with a shebang unless you set `interpreter`. | `string` | `null` | no |
| <a name="input_script_location"></a> [script\_location](#input\_script\_location) | Path to a local script file to upload and run. Set this or `script_content`. | `string` | `null` | no |
| <a name="input_script_name"></a> [script\_name](#input\_script\_name) | File name used on the remote host for `script_content`. Ignored with `script_location`, which keeps the local file name. | `string` | `"script.sh"` | no |
| <a name="input_ssh_agent"></a> [ssh\_agent](#input\_ssh\_agent) | Authenticate with the keys held by the local ssh-agent (`SSH_AUTH_SOCK`). | `bool` | `false` | no |
| <a name="input_ssh_host_key"></a> [ssh\_host\_key](#input\_ssh\_host\_key) | Public host key of the remote host, or of the CA that signed it, such as `ssh-ed25519 AAAA...`. When set, the connection fails if the host presents another key. When null the host key is not checked. | `string` | `null` | no |
| <a name="input_ssh_password"></a> [ssh\_password](#input\_ssh\_password) | Password to log in with when key authentication is not available. Not stored in the state. | `string` | `null` | no |
| <a name="input_ssh_port"></a> [ssh\_port](#input\_ssh\_port) | SSH port of the remote host. | `string` | `22` | no |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input\_ssh\_private\_key) | Private key in OpenSSH or PEM format (the key itself, not a path; use `file()`). Not stored in the state. | `string` | `null` | no |
| <a name="input_ssh_user"></a> [ssh\_user](#input\_ssh\_user) | User to log in as. | `string` | `"root"` | no |
| <a name="input_use_sudo"></a> [use\_sudo](#input\_use\_sudo) | Run the script with `sudo -n`. The SSH user needs passwordless sudo. | `bool` | `false` | no |
| <a name="input_wait_before_deploy"></a> [wait\_before\_deploy](#input\_wait\_before\_deploy) | Sleep for `wait_seconds` on the machine running Terraform before connecting. Uses the local `sleep` command. | `bool` | `false` | no |
| <a name="input_wait_seconds"></a> [wait\_seconds](#input\_wait\_seconds) | Seconds to sleep when `wait_before_deploy` is true. | `number` | `0` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | ID of the run. It changes every time the script runs again. |
| <a name="output_last_hash"></a> [last\_hash](#output\_last\_hash) | The value that decides when the script runs again: the script hash, a timestamp with `deploy_on_every_apply`, or null when changes are ignored. Pass it to `recreate_hook` of another instance to chain runs. |
| <a name="output_script_hash"></a> [script\_hash](#output\_script\_hash) | MD5 of the script contents. |
<!-- END_TF_DOCS -->

## Upgrading

### From 1.0.0

1.0.0 failed to validate (it referenced a `module.this` that did not exist),
so there is nothing to migrate from it. Copy your module block and set a
version of `~> 1.1`.

### From a copy of the module in your own repository

Copies of this module that were kept in other repositories (often as
`modules/ssh-executor-bash`) use the same resource and the same triggers. To
switch, change `source` to the registry address and keep the module block's
name. With default settings `terraform plan` shows no changes and no script
runs again; CI checks this against such a copy. A copy whose scripts ignored
failures will now fail the apply when a script exits non-zero.

## Compatibility

| Tool | Versions tested in CI |
|---|---|
| Terraform | 1.6, 1.13 and the version in [`.tool-versions`](.tool-versions) |
| OpenTofu | 1.6, 1.11 and the version in [`.tool-versions`](.tool-versions) |

The integration tests run against Alpine with OpenSSH. Any Linux or BSD host
with the [requirements](#requirements-on-the-remote-host) above should work.

## Limitations

- Windows hosts and PowerShell scripts are not supported: the run command
  assumes a POSIX shell.
- The script runs through Terraform provisioners, so its output is only in the
  apply log; there is no output with the script's stdout.
- `script_arguments` and the values passed to triggers are stored in the
  state. Do not pass secrets as arguments; render them into `script_content`
  only if your state is protected, or have the script fetch them on the host.
- Changing `deploy_on_script_change` or `deploy_on_every_apply` takes one
  extra apply to settle.
- `wait_before_deploy` uses the local `sleep` command, which Windows machines
  running Terraform do not have.

## FAQ

<details>
<summary><b>Why a null_resource and not terraform_data?</b></summary>

Moving existing state from `null_resource` to `terraform_data` replaces the
resource, which runs every script again, even when the triggers are identical
(checked with Terraform 1.16 and OpenTofu 1.12). Keeping `null_resource` lets
the copies of this module in other repositories switch without that. A move to
`terraform_data` would come in a major release.

</details>

<details>
<summary><b>Is the private key stored in the state?</b></summary>

No. Keys and passwords are only used in the connection block, which Terraform
does not store. What is stored: the triggers (script name and path, the script
hash, the arguments, the port, the timeout, the wait settings, the hook value
and, if set, `use_sudo` and `interpreter`).

</details>

<details>
<summary><b>How do I run the script again without changing it?</b></summary>

`terraform apply -replace='module.setup.null_resource.script'`, or change
`recreate_hook`.

</details>

<details>
<summary><b>How do I get the host key?</b></summary>

`ssh-keyscan -t ed25519 192.0.2.10 2>/dev/null | cut -d' ' -f2-` prints it in
the format `ssh_host_key` expects. Check it against the server's console or
cloud-init output rather than trusting the first answer. For fleets, sign host
keys with an SSH CA and pass the CA's public key.

</details>

<details>
<summary><b>Why does my script work by hand but fail here?</b></summary>

It runs in a non-interactive, non-login shell, so profile files are not read
and `PATH` may be shorter. Use absolute paths or set `PATH` in the script, and
start it with `set -eu` so errors stop it early.

</details>

## Development

Toolchain versions are pinned in [`.tool-versions`](.tool-versions) and CI
reads the same file. Run `asdf install` to get the same Terraform, OpenTofu,
tflint, terraform-docs and just. [`just`](https://just.systems) is the entry
point:

```sh
just                   # list recipes
just check             # fmt-check, validate, lint, test and docs-check
just test              # plan-only unit tests with Terraform and OpenTofu
just test-integration  # real SSH servers in rootless podman, both CLIs
just docs              # regenerate the inputs and outputs tables above
just clean             # remove working files and leftover test containers
```

The integration tests start two throwaway SSH servers (a target and a bastion)
with podman and remove them afterwards; see [CONTRIBUTING.md](CONTRIBUTING.md).

## Contributing and security

Bug reports and pull requests are welcome; see
[CONTRIBUTING.md](CONTRIBUTING.md). Report security problems privately as
described in [SECURITY.md](SECURITY.md). This project follows the
[Contributor Covenant](CODE_OF_CONDUCT.md). Changes are listed in
[CHANGELOG.md](CHANGELOG.md).

## License

[Apache License 2.0](LICENSE).
