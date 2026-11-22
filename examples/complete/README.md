# Complete example

Configures two servers in a private network through a bastion:

- the install script is rendered with `templatefile()` and passed as
  `script_content`, so it runs again when the template or its variables change;
- it runs with `sudo` from `/var/tmp` through `sh`, for servers where `/tmp` is
  mounted `noexec`;
- host keys of the bastion and the servers are checked against one CA key;
- `recreate_hook` runs the install again when a server is replaced, and chains
  a report script that runs on every apply after it.

```sh
terraform init   # or: tofu init
terraform plan
```
