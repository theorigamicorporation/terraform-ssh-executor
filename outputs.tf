output "id" {
  description = "ID of the run. It changes every time the script runs again."
  value       = null_resource.script.id
}

output "script_hash" {
  description = "MD5 of the script contents."
  value       = local.script_hash
}

output "last_hash" {
  description = "The value that decides when the script runs again: the script hash, a timestamp with `deploy_on_every_apply`, or null when changes are ignored. Pass it to `recreate_hook` of another instance to chain runs."
  value       = null_resource.script.triggers.file_changed
}
