locals {
  # Generate filter expressions for each user agent
  json_payload_filters = [for agent in var.probe_user_agents : "jsonPayload.http_user_agent=~\"${agent}\""]
  text_payload_filters = [for agent in var.probe_user_agents : "textPayload=~\"${agent}\""]

  # Combine all filters into one string
  probe_filter_expr = join(" OR ", concat(local.json_payload_filters, local.text_payload_filters))
  probe_filter      = "resource.type=\"k8s_container\" AND (${local.probe_filter_expr})"

  # Generate GCP log filter expressions for k8s_log_exclusions entries.
  # Namespace scope targets a single Kubernetes namespace; cluster scope targets all namespaces in a GKE cluster.
  # coalesce(..., "") guards against null interpolation when scope/namespace/cluster_name are inconsistent —
  # the precondition on the resource will surface the intended error message before apply proceeds.
  k8s_log_exclusion_filters = {
    for k, v in var.k8s_log_exclusions : k => (
      v.scope == "namespace"
      ? join("\n", [
        "resource.type=\"k8s_container\"",
        "resource.labels.namespace_name=\"${coalesce(v.namespace, "")}\"",
        "severity<\"${v.exclude_below_severity}\"",
      ])
      : join("\n", [
        "resource.type=\"k8s_container\"",
        "resource.labels.cluster_name=\"${coalesce(v.cluster_name, "")}\"",
        "severity<\"${v.exclude_below_severity}\"",
      ])
    )
  }
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
  count = lookup(var.enable_exclusions, "fluentbit_gke", true) ? 1 : 0

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

# Structured Kubernetes log exclusions. One resource per k8s_log_exclusions entry.
# The resource persists in state even when enabled = false (disabled = true in GCP),
# allowing toggle without destroy/recreate.
resource "google_logging_project_exclusion" "k8s_log_exclusions" {
  for_each = var.k8s_log_exclusions

  project     = var.project_id
  name        = each.key
  description = each.value.description
  filter      = local.k8s_log_exclusion_filters[each.key]
  disabled    = !each.value.enabled

  lifecycle {
    precondition {
      condition     = !(each.value.scope == "namespace" && (each.value.namespace == null || trimspace(each.value.namespace) == ""))
      error_message = "k8s_log_exclusions[\"${each.key}\"]: 'namespace' must be set to a non-empty string when scope is \"namespace\"."
    }

    precondition {
      condition     = !(each.value.scope == "cluster" && (each.value.cluster_name == null || trimspace(each.value.cluster_name) == ""))
      error_message = "k8s_log_exclusions[\"${each.key}\"]: 'cluster_name' must be set to a non-empty string when scope is \"cluster\"."
    }
  }
}

# Custom log exclusions with arbitrary GCP filter strings.
# The map key is used as the GCP exclusion name.
# The resource persists in state even when enabled = false (disabled = true in GCP).
resource "google_logging_project_exclusion" "custom_exclusions" {
  for_each = var.custom_exclusions

  project     = var.project_id
  name        = each.key
  description = each.value.description
  filter      = each.value.filter
  disabled    = !each.value.enabled
}
