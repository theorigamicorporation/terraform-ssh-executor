#!/bin/sh
# Example script: installs a package and writes a file. Keep scripts
# idempotent, because they run again when they change.
set -eu
apt-get update -qq
apt-get install -y -qq chrony
echo "managed by Terraform" > /etc/motd
