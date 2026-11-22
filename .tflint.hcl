config {
  call_module_type = "none"
}

plugin "terraform" {
  enabled = true
  version = "0.17.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  preset  = "all"
}
