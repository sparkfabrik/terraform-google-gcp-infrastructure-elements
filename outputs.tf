output "probe_exclusion_filter" {
  description = "The filter used for probe exclusions"
  value       = local.probe_filter
}

output "probe_exclusion_id" {
  description = "The ID of the probe exclusion resource"
  value       = lookup(var.enable_exclusions, "probe_exclusion", true) ? google_logging_project_exclusion.probe_exclusion[0].id : null
}

output "default_exclusion_id" {
  description = "The ID of the default exclusion resource"
  value       = lookup(var.enable_exclusions, "default_k8s_exclusion", true) ? google_logging_project_exclusion.default_exclusion[0].id : null
}

output "gke_metadata_server_exclusion_id" {
  description = "The ID of the GKE metadata server exclusion resource"
  value       = lookup(var.enable_exclusions, "gke_metadata_server_sync_sandbox", true) ? google_logging_project_exclusion.gke_metadata_server_exclusion_sync_sandbox[0].id : null
}
output "fluentbit_gke_exclusion_id" {
  description = "The ID of the Fluentbit GKE exclusion resource"
  value       = lookup(var.enable_exclusions, "fluentbit_gke", true) ? google_logging_project_exclusion.fluentbit_gke_parse_time[0].id : null
}
output "fpm_exclusion_id" {
  description = "The ID of the FPM exclusion resource"
  value       = lookup(var.enable_exclusions, "fpm", true) ? google_logging_project_exclusion.fpm[0].id : null
}
