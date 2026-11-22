# Developer entry point. CI runs the same recipes.
# Toolchain versions are pinned in .tool-versions (run `asdf install`).

set shell := ["bash", "-euo", "pipefail", "-c"]

examples := "examples/simple examples/complete"

# Show the available recipes
default:
    @just --list

# Format all Terraform files
fmt:
    terraform fmt -recursive

# Fail if any Terraform file is not formatted
fmt-check:
    terraform fmt -recursive -check -diff

# Validate the module and the examples with Terraform and OpenTofu
validate: (validate-with "terraform") (validate-with "tofu")

# Validate the module and the examples with one CLI
validate-with cli:
    for dir in . {{examples}}; do \
      echo "==> {{cli}} validate $dir"; \
      {{cli}} -chdir="$dir" init -backend=false -input=false -upgrade >/dev/null; \
      {{cli}} -chdir="$dir" validate; \
    done

# Run tflint on the module and the examples
lint:
    tflint --init
    tflint --format compact
    for dir in {{examples}}; do tflint --chdir="$dir" --config="$PWD/.tflint.hcl" --format compact; done

# Plan-only unit tests with Terraform and OpenTofu (nothing connects anywhere)
test: (test-with "terraform") (test-with "tofu")

# Plan-only unit tests with one CLI
test-with cli:
    {{cli}} init -backend=false -input=false -upgrade >/dev/null
    {{cli}} test

# Integration tests against SSH servers in rootless podman, with Terraform and OpenTofu
test-integration: (test-integration-with "terraform") (test-integration-with "tofu")

# Integration tests with one CLI
test-integration-with cli:
    tests/integration/run.sh {{cli}}

# Write the inputs and outputs tables into README.md
docs:
    terraform-docs .

# Fail if the README tables are out of date
docs-check: docs
    @git diff --exit-code -- README.md || \
      (echo; echo "README.md is out of date. Run 'just docs' and commit the result."; exit 1)

# Everything CI runs except the integration tests
check: fmt-check validate lint test docs-check

# Remove Terraform working files and leftover test containers
clean:
    find . -name '.terraform' -type d -prune -exec rm -rf {} +
    find . \( -name '.terraform.lock.hcl' -o -name 'terraform.tfstate*' \) -not -path './.git/*' -delete
    rm -rf tests/integration/upgrade/module
    -podman ps -aq --filter name=tf-ssh-executor-it- | xargs -r podman rm -f -v
    -podman network ls -q --filter name=tf-ssh-executor-it- | xargs -r podman network rm -f
    -podman rmi -f localhost/terraform-ssh-executor-sshd:test 2>/dev/null
