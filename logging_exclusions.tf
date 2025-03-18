locals {
  # Generate filter expressions for each user agent
  json_payload_filters = [for agent in var.probe_user_agents : "jsonPayload.http_user_agent=~\"${agent}\""]
  text_payload_filters = [for agent in var.probe_user_agents : "textPayload=~\"${agent}\""]

  # Combine all filters into one string
  probe_filter_expr = join(" OR ", concat(local.json_payload_filters, local.text_payload_filters))
  probe_filter      = "resource.type=\"k8s_container\"\n(${local.probe_filter_expr})"
}

resource "google_logging_project_exclusion" "probe_exclusion" {
  count = lookup(var.enable_exclusions, "probe_exclusion", true) ? 1 : 0

  project     = var.project_id
  name        = "health-probe-exclusion"
  description = "Exclusion for health probes"
  filter      = local.probe_filter
}

resource "google_logging_project_exclusion" "default_exclusion" {
  count = lookup(var.enable_exclusions, "default_k8s_exclusion", true) ? 1 : 0

  project     = var.project_id
  name        = "default-k8s-exclusion"
  description = "Default log exclusion for k8s cluster resources"
  filter      = var.default_exclusion_filter
}

resource "google_logging_project_exclusion" "gke_metadata_server_exclusion_sync_sandbox" {
  count = lookup(var.enable_exclusions, "gke_metadata_server_sync_sandbox", true) ? 1 : 0

  project     = var.project_id
  name        = "gke-metadata-server-exclusion-sync-sandbox"
  description = "Exclude failed to sync sandbox log"
  filter      = var.gke_metadata_server_exclusion_sync_sandbox
}

resource "google_logging_project_exclusion" "fluentbit_gke_parse_time" {
  count = lookup(var.enable_exclusions, "fluentbit-gke", true) ? 1 : 0

  project     = var.project_id
  name        = "fluentbit-gke-parse-time"
  description = "Exclude fluentbit-gke logs for failed to parse time"
  filter      = var.fluentbit_gke
}

resource "google_logging_project_exclusion" "fpm" {
  count = lookup(var.enable_exclusions, "fpm", true) ? 1 : 0

  project     = var.project_id
  name        = "fpm-exclusion"
  description = "Exclude fpm logs"
  filter      = var.fpm
}
