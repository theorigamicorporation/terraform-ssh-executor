#!/usr/bin/env bash
# Integration tests: starts two throwaway SSH servers (a target and a bastion)
# in rootless podman, runs the module against them with terraform or tofu, and
# removes everything it created on exit.
#
#   tests/integration/run.sh terraform
#   tests/integration/run.sh tofu
#
# Set KEEP_IMAGE=1 to keep the test image between runs.
set -euo pipefail

cli="${1:-terraform}"
command -v "$cli" >/dev/null || { echo "$cli not found" >&2; exit 1; }
command -v podman >/dev/null || { echo "podman not found" >&2; exit 1; }

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"

id="tf-ssh-executor-it-$$"
image="localhost/terraform-ssh-executor-sshd:test"
work="$(mktemp -d)"

cleanup() {
  status=$?
  podman rm -f -v "$id-target" "$id-bastion" >/dev/null 2>&1 || true
  podman network rm -f "$id" >/dev/null 2>&1 || true
  if [[ "${KEEP_IMAGE:-}" != "1" ]]; then
    podman rmi -f "$image" >/dev/null 2>&1 || true
  fi
  for dir in tests/integration/upgrade tests/integration/negative; do
    rm -rf "${dir:?}/.terraform" "${dir:?}/module"
    rm -f "$dir"/.terraform.lock.hcl "$dir"/terraform.tfstate "$dir"/terraform.tfstate.backup
  done
  rm -rf "${work:?}"
  exit "$status"
}
trap cleanup EXIT

# Error messages are wrapped to the terminal width, so match on one line.
log_has() { tr -s '[:space:]' ' ' <"$1" | grep -qi -- "$2"; }
step() { printf '\n==> %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

step "Generating keys"
mkdir -p "$work/keys"
ssh-keygen -q -t ed25519 -N '' -C client -f "$work/keys/client_ed25519"
ssh-keygen -q -t ed25519 -N '' -C host -f "$work/keys/host_ed25519"
ssh-keygen -q -t ed25519 -N '' -C other -f "$work/other_host"
# The containers read the keys through a rootless user namespace, so the mounted
# copies are world-readable; ssh itself gets a private copy.
chmod 0644 "$work/keys/"*
install -m 0600 "$work/keys/client_ed25519" "$work/client_key"

step "Starting the SSH servers"
podman build -q -t "$image" tests/integration/sshd >/dev/null 2>"$work/build.log" || { cat "$work/build.log"; fail "podman build failed"; }
podman network create "$id" >/dev/null
# Both servers share one host key, so one ssh_host_key value checks both.
podman run -d --name "$id-target" --network "$id" --network-alias target \
  -p 127.0.0.1::22 --tmpfs /scratch:rw,noexec,mode=1777 \
  -v "$work/keys:/keys:ro,Z" "$image" >/dev/null
podman run -d --name "$id-bastion" --network "$id" \
  -p 127.0.0.1::22 -v "$work/keys:/keys:ro,Z" "$image" >/dev/null

port_of() { podman port "$1" 22/tcp | head -n 1 | sed 's/.*://'; }
target_port="$(port_of "$id-target")"
bastion_port="$(port_of "$id-bastion")"

for port in "$target_port" "$bastion_port"; do
  for _ in $(seq 1 30); do
    ssh-keyscan -T 2 -p "$port" 127.0.0.1 >/dev/null 2>&1 && break
    sleep 1
  done
  ssh-keyscan -T 2 -p "$port" 127.0.0.1 >/dev/null 2>&1 || fail "SSH server on port $port did not come up"
done

host_key="$(cut -d' ' -f1,2 "$work/keys/host_ed25519.pub")"
export TF_VAR_ssh_host=127.0.0.1
export TF_VAR_ssh_port="$target_port"
export TF_VAR_ssh_user=tester
TF_VAR_ssh_private_key="$(cat "$work/keys/client_ed25519")"
export TF_VAR_ssh_private_key
export TF_VAR_ssh_host_key="$host_key"
export TF_VAR_bastion_port="$bastion_port"
export TF_VAR_bastion_host_key="$host_key"
export TF_IN_AUTOMATION=1
# The legacy copy does not set agent = false, so a stale local agent socket
# would break its connection.
unset SSH_AUTH_SOCK

on_target() {
  ssh -i "$work/client_key" -p "$target_port" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
    tester@127.0.0.1 "$@"
}

step "$cli test (tests/integration)"
"$cli" init -input=false -backend=false >/dev/null
"$cli" test -test-directory=tests/integration

step "A failing script fails the apply and leaves no file behind"
neg=(-chdir=tests/integration/negative)
"$cli" "${neg[@]}" init -input=false >/dev/null
if "$cli" "${neg[@]}" apply -auto-approve -input=false -no-color \
  -var 'script_content=#!/bin/sh
echo failing on purpose; exit 7' >"$work/fail.log" 2>&1; then
  fail "apply succeeded although the script exited with 7"
fi
log_has "$work/fail.log" 'status 7' || { cat "$work/fail.log"; fail "exit status 7 not reported"; }
left="$(on_target 'ls /tmp/terraform-ssh-executor-* 2>/dev/null | wc -l')" || fail "cannot reach the target"
[[ "$left" -eq 0 ]] || fail "the script was left on the host after a failure"
"$cli" "${neg[@]}" destroy -auto-approve -input=false -var 'script_content=x' >/dev/null

step "A wrong host key is rejected"
if TF_VAR_ssh_host_key="$(cut -d' ' -f1,2 "$work/other_host.pub")" \
  "$cli" "${neg[@]}" apply -auto-approve -input=false -no-color \
  -var 'script_content=#!/bin/sh
touch /tmp/should-not-exist' >"$work/hostkey.log" 2>&1; then
  fail "apply succeeded with the wrong host key"
fi
log_has "$work/hostkey.log" 'host key\|handshake' || { cat "$work/hostkey.log"; fail "host key error not reported"; }
ran="$(on_target 'ls /tmp/should-not-exist 2>/dev/null | wc -l')" || fail "cannot reach the target"
[[ "$ran" -eq 0 ]] || fail "the script ran despite the wrong host key"

step "Upgrading from the legacy copy plans no changes"
up=(-chdir=tests/integration/upgrade)
ln -sfn legacy-module tests/integration/upgrade/module
"$cli" "${up[@]}" init -input=false >/dev/null
"$cli" "${up[@]}" apply -auto-approve -input=false >/dev/null
ln -sfn ../../.. tests/integration/upgrade/module
"$cli" "${up[@]}" init -input=false >/dev/null
set +e
"$cli" "${up[@]}" plan -input=false -no-color -detailed-exitcode >"$work/upgrade.log" 2>&1
code=$?
set -e
[[ "$code" -eq 0 ]] || { cat "$work/upgrade.log"; fail "switching from the legacy copy plans changes (exit $code)"; }

step "All integration checks passed with $cli"
