# Examples

- [simple](simple): one script file on one server.
- [complete](complete): a rendered script, sudo, a bastion, host key checks,
  `noexec` directories and chained runs across several servers.

The examples use `source = "../.."` so CI checks them against the current
code. In your own configuration use the registry address and a version:

```hcl
module "setup" {
  source  = "theorigamicorporation/executor/ssh"
  version = "~> 1.1"
  # ...
}
```

The examples use documentation addresses (192.0.2.0/24, 203.0.113.0/24) and
private ranges; nothing in them points at a real host.
