output "install_runs" {
  description = "ID of the last agent install per server. It changes whenever the install runs again."
  value       = { for k, m in module.install_agent : k => m.id }
}
