# Security policy

## Supported versions

Security fixes go into the latest minor release.

## Reporting a vulnerability

Please do not open a public issue. Use GitHub's private vulnerability reporting
("Report a vulnerability" under the Security tab of this repository) or write
to office@theorigamicorporation.com. You should get an answer within a week.

Include the module version, the Terraform or OpenTofu version, the remote OS
and steps to reproduce. Leave out real keys, passwords and addresses.

## Things to know

- Set `ssh_host_key` (and `bastion_host_key`). Without them the module accepts
  any host key, so a machine in the middle could receive your script and run
  whatever it wants in its place.
- Private keys and passwords are not written to the state. The triggers are:
  script name and path, script hash, `script_arguments`, port, timeout, wait
  settings, `recreate_hook`, and `use_sudo` and `interpreter` when set. Do not
  pass secrets in `script_arguments` or `recreate_hook`.
- A script given as `script_content` is not stored in the state, only its
  hash.
- The script is uploaded to `remote_directory` (default `/tmp`) with a name
  that contains a random run ID and is removed after the run. On hosts shared
  with untrusted users, point `remote_directory` at a directory only the SSH
  user can write to.
- `TF_LOG=DEBUG` output includes the commands sent to the host, including
  `script_arguments`.
