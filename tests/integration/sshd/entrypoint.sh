#!/bin/sh
# Takes the host key and the authorized key from /keys, mounted by run.sh.
set -eu
install -m 0600 /keys/host_ed25519 /etc/ssh/ssh_host_ed25519_key
install -d -m 0700 -o tester -g tester /home/tester/.ssh
install -m 0600 -o tester -g tester /keys/client_ed25519.pub /home/tester/.ssh/authorized_keys
exec /usr/sbin/sshd -D -e
