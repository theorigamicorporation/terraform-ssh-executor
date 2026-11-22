# Contributing

Thanks for helping. Bug reports with the module version, the Terraform or
OpenTofu version, the remote OS and the relevant part of the apply log (with
addresses and secrets replaced) are the most useful thing you can send.

## Setup

1. Install the pinned toolchain: `asdf install` (see `.tool-versions`). If you
   do not use asdf, install the same versions of Terraform, OpenTofu, tflint,
   terraform-docs and just some other way.
2. For the integration tests, install rootless [podman](https://podman.io)
   and an OpenSSH client (`ssh`, `ssh-keygen`, `ssh-keyscan`).
3. Run `just` to see the recipes. CI runs the same ones.

## Day to day

```sh
just fmt                          # terraform fmt
just check                        # fmt-check, validate, lint, test, docs-check
just test-with tofu               # unit tests with one CLI
just test-integration             # integration tests with both CLIs
just test-integration-with terraform
just docs                         # regenerate the README tables
```

Commit the regenerated README with your change; CI fails when it drifts.

## Tests

- Unit tests (`tests/*.tftest.hcl`) only plan, so they need no SSH server.
  They pin the trigger keys and values that decide when a script runs again;
  changing those runs every user's script again on upgrade, so treat a change
  there as breaking.
- Integration tests (`tests/integration/`) start two throwaway SSH servers in
  rootless podman: a target with a `noexec` tmpfs at `/scratch`, and a bastion
  on the same network. `run.sh` runs `terraform test` / `tofu test` against
  them, then checks that a failing script fails the apply, that a wrong host
  key is rejected and that switching from the older copy of the module in
  `tests/integration/upgrade/legacy-module` plans no changes. It removes the
  containers, the network and the test image when it exits, also on failure.
  Set `KEEP_IMAGE=1` to keep the image between runs.
- New inputs need a unit test, and an integration test if they change what
  happens on the host.

## Pull requests

- Keep changes focused and describe what you tested.
- Fill in the pull request template.
- Examples and tests must use documentation addresses (192.0.2.0/24,
  198.51.100.0/24, 203.0.113.0/24, RFC 1918 ranges) and never real keys or
  hosts.
- Add a line to `CHANGELOG.md` under "Unreleased".

## Releases

Maintainers move the "Unreleased" section of `CHANGELOG.md` under a version
heading, merge, and push a `v<version>` tag. The release workflow creates the
GitHub release with that section as notes, and the registries pick up the tag.

## Design notes

`openspec/specs/` holds the current requirements, and the archived OpenSpec
changes in `openspec/changes/archive/` explain past decisions, such as why the
module keeps `null_resource`. Start larger changes with an OpenSpec change.
