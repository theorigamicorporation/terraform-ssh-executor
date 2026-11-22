# Simple example

Uploads [`scripts/setup.sh`](scripts/setup.sh) to one server, runs it as root
and runs it again whenever the script changes.

```sh
terraform init   # or: tofu init
terraform plan -var host=192.0.2.10 -var "host_key=$(ssh-keyscan -t ed25519 192.0.2.10 2>/dev/null | cut -d' ' -f2-)"
terraform apply
```
