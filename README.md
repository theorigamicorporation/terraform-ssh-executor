# Terraform SSH Executor Module

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
<!--- TODO: Add code quality badge. -->
<!--- TODO: Add release version badge. -->
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

<p align="center">
  <img height="150" src="https://theorigamicorporation.com/wp-content/uploads/2024/02/logo-7k-dropshadow.png">
  <h3 align="center">Helping you build the future</h3>
</p>

---

Terraform module to easily execute scripts via SSH with many customizable features

## USAGE

A basic usage of the module is as follows:

```terraform
module "template" {
  source                  = "thereisnotime/terraform-ssh-executor"
  version                 = "x.x.x" # Replace with the latest version
  depends_on              = [module.ec2_vm] # The resources that the script depends on, usually your virtual machine.
  script_location         = "${path.module}/../../scripts/setup-generic.sh" # The location of the script to run.
  ssh_private_key         = tls_private_key.tf_rsa_key.private_key_openssh # The private key to connect to the remote machine.
  ssh_host                = "192.168.3.5" # The IP address of the remote machine.
  deploy_on_script_change = true # Set to true if you want Terraform to re-apply every time your script has changes.
  ssh_user                = "terraform" # The user to connect to the remote machine.
  recreate_hook           = module.ec2_warden_vm.instance_arn # In case you want the script to re-create itself if another resource changes.
  wait_before_deploy      = true # Set to true if you want Terraform to wait for some time before running.
  wait_seconds            = 30 # How many seconds to wait before running the script.
}
```

## NOTES

_TODO_

## EXAMPLES

- [Simple](examples/simple) - Basic usage of the module
- [Complete](examples/complete) - Advanced usage of the module

<!-- BEGIN_TF_DOCS -->




__TODO__
<!-- END_TF_DOCS -->

## CONTRIBUTING

Contributions are very welcomed!

Start by reviewing [contribution guide](CONTRIBUTING.md) and our [code of conduct](CODE_OF_CONDUCT.md). After that, start coding and ship your changes by creating a new PR.

## ROADMAP

- [ ] Add simple and complete examples.
- [ ] Add examples for PowerShell.
- [ ] Add examples for sshpass.

## LICENSE

Apache 2 Licensed. See [LICENSE](LICENSE) for full details.

## AUTHORS

<!--- Replace repository name -->
<a href="https://github.com/theorigamicorporation/terraform-ssh-executor/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=theorigamicorporation/terraform-ssh-executor" />
</a>

Made with [contrib.rocks](https://contrib.rocks).