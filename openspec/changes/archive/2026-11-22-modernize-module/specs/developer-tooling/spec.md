## ADDED Requirements

### Requirement: Pinned toolchain
The repository SHALL pin Terraform, OpenTofu, tflint, terraform-docs and just in `.tool-versions`, and CI SHALL install the same versions from that file.

#### Scenario: Version bump
- **WHEN** a version in `.tool-versions` changes
- **THEN** CI uses the new version without other edits

### Requirement: justfile entry point
A `justfile` SHALL provide fmt, fmt-check, validate, lint, test, test-integration, docs, docs-check, check and clean recipes, with per-CLI variants for validate, test and test-integration, and CI SHALL call these recipes.

#### Scenario: Local check
- **WHEN** a developer runs `just check`
- **THEN** formatting, validation with both CLIs, tflint, unit tests with both CLIs and the README drift check run

### Requirement: Integration servers
`tests/integration/run.sh` SHALL start a target and a bastion SSH server in rootless podman, run the integration tests with the given CLI, and remove the containers, network and test image on exit, including on failure.

#### Scenario: Interrupted run
- **WHEN** a test fails halfway
- **THEN** no `tf-ssh-executor-it-*` container or network is left behind

### Requirement: Quality gates
CI SHALL run format, tflint and README drift checks, validation and unit tests on Terraform 1.6, 1.13 and the pinned version and OpenTofu 1.6, 1.11 and the pinned version, and integration tests on the oldest and pinned version of each. Actions SHALL be pinned by commit SHA.

#### Scenario: README drift
- **WHEN** a variable changes without regenerated README tables
- **THEN** the lint job fails and says to run `just docs`

### Requirement: Releases
Pushing a `v<version>` tag SHALL create a GitHub release whose notes are the matching section of CHANGELOG.md, and SHALL fail when that section is missing.

#### Scenario: Missing notes
- **WHEN** `v1.2.0` is pushed and CHANGELOG.md has no `## 1.2.0` section
- **THEN** the release job fails and no release is created
