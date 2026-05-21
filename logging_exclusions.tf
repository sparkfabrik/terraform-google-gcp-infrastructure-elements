locals {
  # Generate filter expressions for each user agent
  json_payload_filters = [for agent in var.probe_user_agents : "jsonPayload.http_user_agent=~\"${agent}\""]
  text_payload_filters = [for agent in var.probe_user_agents : "textPayload=~\"${agent}\""]

  # Combine all filters into one string
  probe_filter_expr = join(" OR ", concat(local.json_payload_filters, local.text_payload_filters))
  probe_filter      = "resource.type=\"k8s_container\" AND (${local.probe_filter_expr})"

  # Generate GCP log filter expressions for k8s_log_exclusions entries.
  # Builds a dynamic clause list: base scope + optional container_name + optional pod label + severity.
  # trimspace(coalesce(..., "")) guards against null interpolation and trims whitespace-only values,
  # keeping filter generation consistent with the trimspace() checks in the resource preconditions.
  # Clauses are joined with AND to match established module style and avoid Cloud Logging filter ambiguity.
  k8s_log_exclusion_filters = {
    for k, v in var.k8s_log_exclusions : k => join(" AND\n", concat(
      # Base: resource type + cluster (always present)
      [
        "resource.type=\"k8s_container\"",
        "resource.labels.cluster_name=\"${trimspace(v.cluster_name)}\"",
      ],
      # Namespace clause (only for namespace scope)
      v.scope == "namespace"
      ? ["resource.labels.namespace_name=\"${trimspace(coalesce(v.namespace, ""))}\""]
      : [],
      # Optional: container name selector
      v.container_name != null && trimspace(v.container_name) != ""
      ? ["resource.labels.container_name=\"${trimspace(v.container_name)}\""]
      : [],
      # Optional: pod label selector
      v.pod_label_key != null && v.pod_label_value != null
      ? ["labels.k8s-pod/${trimspace(v.pod_label_key)}=\"${trimspace(v.pod_label_value)}\""]
      : [],
      # Severity threshold (always last)
      ["severity<\"${v.exclude_below_severity}\""],
    ))
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
      condition     = trimspace(each.value.cluster_name) != ""
      error_message = "k8s_log_exclusions[\"${each.key}\"]: 'cluster_name' must be a non-empty string."
    }

    precondition {
      condition     = !(each.value.scope == "namespace" && (each.value.namespace == null || trimspace(each.value.namespace) == ""))
      error_message = "k8s_log_exclusions[\"${each.key}\"]: 'namespace' must be set to a non-empty string when scope is \"namespace\"."
    }

    precondition {
      condition     = !(each.value.scope == "cluster" && each.value.namespace != null)
      error_message = "k8s_log_exclusions[\"${each.key}\"]: 'namespace' must not be set when scope is \"cluster\"."
    }

    precondition {
      condition     = each.value.container_name == null || trimspace(each.value.container_name) != ""
      error_message = "k8s_log_exclusions[\"${each.key}\"]: 'container_name' must be non-empty when set."
    }

    precondition {
      condition     = each.value.pod_label_key == null || trimspace(each.value.pod_label_key) != ""
      error_message = "k8s_log_exclusions[\"${each.key}\"]: 'pod_label_key' must be non-empty when set."
    }

    precondition {
      condition     = each.value.pod_label_value == null || trimspace(each.value.pod_label_value) != ""
      error_message = "k8s_log_exclusions[\"${each.key}\"]: 'pod_label_value' must be non-empty when set."
    }
  }
}

# Cross-variable validation: ensure custom_exclusions and k8s_log_exclusions keys
# don't overlap, since both map keys become GCP exclusion names (unique per project).
# This cannot live inside a variable validation block (Terraform < 1.9 restriction),
# so we use a terraform_data precondition which evaluates at plan time.
resource "terraform_data" "validate_exclusion_keys" {
  lifecycle {
    precondition {
      condition = length(setintersection(
        toset(keys(var.custom_exclusions)),
        toset(keys(var.k8s_log_exclusions))
      )) == 0
      error_message = "custom_exclusions keys must not overlap with k8s_log_exclusions keys because both map keys are used as GCP exclusion names and must be unique per project."
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
