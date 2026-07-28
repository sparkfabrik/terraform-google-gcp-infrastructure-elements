variable "project_id" {
  description = "The Google Cloud project ID where logging exclusions will be created"
  type        = string
}

###########################
# Kyverno firewall rule
###########################
variable "kyverno_firewall_rule" {
  description = "Rule to configure the Kyverno admission webhook firewall rule"
  type = object({
    enable        = bool
    network       = string
    source_ranges = list(string)
    name          = optional(string)
    description   = optional(string)
    direction     = optional(string)
    priority      = optional(number)
    protocol      = optional(string)
    ports         = optional(list(string))
  })
  default = {
    enable        = false
    name          = "kyverno-admission-webhook"
    network       = ""
    description   = "Allow Kyverno admission webhook from control plane to nodes"
    direction     = "INGRESS"
    priority      = 1000
    source_ranges = []
    protocol      = "tcp"
    ports         = ["9443"]
  }
  validation {
    condition     = var.kyverno_firewall_rule.enable == false || (var.kyverno_firewall_rule.network != "" && length(var.kyverno_firewall_rule.source_ranges) > 0)
    error_message = "When 'enable' is true, 'network' must be set and 'source_ranges' must contain at least one CIDR range."
  }
}

###########################
# SSL default policy
###########################
variable "enable_ssl_policy" {
  description = "Enable SSL policy creation"
  type        = bool
  default     = true
}

variable "ssl_modern_policy_description" {
  description = "Description for the SSL policy"
  type        = string
  default     = "Modern SSL policy with minimum TLS version 1.2"
}

###########################
# Logging Exclusions
###########################
variable "enable_exclusions" {
  description = "Map of boolean flags to enable/disable individual exclusions. `k8s_node_system_noise` is opt-in (defaults to false): it silences node-level system logs and should be enabled on development platforms only."
  type        = map(bool)
  default = {
    probe_exclusion                  = true
    default_k8s_exclusion            = true
    gke_metadata_server_sync_sandbox = true
    fluentbit_gke                    = true
    fpm                              = true
    k8s_node_system_noise            = false
  }
}

variable "k8s_node_system_noise_logs" {
  description = "Log IDs of the k8s_node system logs excluded by the opt-in `k8s_node_system_noise` exclusion. These logs are typically written at severity DEFAULT in very high volume (kubelet alone can exceed 50M entries/week on a busy cluster) and drive Cloud Logging ingestion cost."
  type        = list(string)
  default = [
    "kubelet",
    "container-runtime",
    "fluentbit",
    "gcfs-snapshotter",
    "gcfsd",
  ]

  validation {
    condition     = length(var.k8s_node_system_noise_logs) > 0
    error_message = "k8s_node_system_noise_logs must contain at least one log ID when the exclusion is enabled."
  }
}

variable "k8s_node_system_noise_exclude_below_severity" {
  description = "Entries of the k8s_node system logs strictly below this severity are excluded when `k8s_node_system_noise` is enabled. Entries at or above this severity are always ingested."
  type        = string
  default     = "WARNING"

  validation {
    condition = contains([
      "DEFAULT", "DEBUG", "INFO", "NOTICE", "WARNING",
      "ERROR", "CRITICAL", "ALERT", "EMERGENCY"
    ], var.k8s_node_system_noise_exclude_below_severity)
    error_message = "k8s_node_system_noise_exclude_below_severity must be one of: DEFAULT, DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, ALERT, EMERGENCY."
  }
}

variable "probe_user_agents" {
  description = "List of probe user agents to exclude from logs"
  type        = list(string)
  default = [
    "kube-probe",
    "GoogleHC"
  ]
}

variable "default_exclusion_filter" {
  description = "Filter for default log exclusion"
  type        = string
  default     = <<EOT
resource.type="k8s_cluster" AND (protoPayload.authenticationInfo.principalEmail=~"container-engine-robot.iam.gserviceaccount.com" OR protoPayload.authenticationInfo.principalEmail="system:kubestore-collector" OR protoPayload.authenticationInfo.principalEmail="system:cloud-controller-manager" OR protoPayload.authenticationInfo.principalEmail="system:kube-scheduler" OR protoPayload.authenticationInfo.principalEmail="system:cluster-autoscaler" OR protoPayload.authenticationInfo.principalEmail="system:l7-lb-controller" OR protoPayload.authenticationInfo.principalEmail="system:kube-controller-manager" OR protoPayload.authenticationInfo.principalEmail="system:serviceaccount:kube-system:metrics-server" OR protoPayload.authenticationInfo.principalEmail="system:addon-manager" OR protoPayload.authenticationInfo.principalEmail="system:vpa-recommender" OR protoPayload.authenticationInfo.principalEmail="system:gke-master-healthcheck" OR protoPayload.authenticationInfo.principalEmail="system:managed-certificate-controller" OR protoPayload.authenticationInfo.principalEmail="system:clustermetrics" OR protoPayload.authenticationInfo.principalEmail="system:pd-csi-controller" OR protoPayload.authenticationInfo.principalEmail="system:konnectivity-server" OR protoPayload.authenticationInfo.principalEmail="system:serviceaccount:kube-system:kube-dns-autoscaler" OR protoPayload.authenticationInfo.principalEmail="system:serviceaccount:kube-system:generic-garbage-collector" OR protoPayload.authenticationInfo.principalEmail="system:gke-common-webhooks" OR protoPayload.authenticationInfo.principalEmail="system:serviceaccount:kube-system:resourcequota-controller" OR protoPayload.authenticationInfo.principalEmail="system:serviceaccount:kube-system:konnectivity-agent-cpha" OR protoPayload.authenticationInfo.principalEmail="system:serviceaccount:kube-system:persistent-volume-binder" OR (protoPayload.authenticationInfo.principalEmail="system:apiserver" AND protoPayload.methodName="io.k8s.core.v1.endpoints.get") OR protoPayload.methodName=~"watch" OR protoPayload.methodName=~"io.k8s.apiserver.flowcontrol" OR protoPayload.methodName=~"io.k8s.discovery.v1.endpointslices" OR protoPayload.methodName=~"io.k8s.v1.nodes.watch" OR protoPayload.methodName=~"io.k8s.coordination.v1.leases" OR protoPayload.methodName=~"io.k8s.core.v1.componentstatuses" OR protoPayload.methodName=~"io.k8s.autoscaling" OR protoPayload.methodName=~"io.k8s.metrics.v1beta1" OR protoPayload.methodName=~"io.k8s.authorization.v1.selfsubjectaccessreviews" OR protoPayload.methodName=~"io.k8s.core.v1.nodes.status.patch" OR (protoPayload.methodName=~"io.k8s.get" AND protoPayload.resourceName=~"metrics") OR (protoPayload.methodName=~"io.k8s.core.v1.configmaps.get" AND protoPayload.resourceName=~"metrics") OR protoPayload.resourceName="readyz" OR protoPayload.resourceName="livez")
EOT
}

variable "gke_metadata_server_exclusion_sync_sandbox" {
  description = "Filter for gke-metadata-server exclusion for failed to sync sandbox"
  type        = string
  default     = <<EOT
resource.type="k8s_container" AND
severity=INFO AND
resource.labels.namespace_name="kube-system" AND
labels.k8s-pod/k8s-app="gke-metadata-server" AND
jsonPayload.message=~"Unable to sync sandbox"
EOT
}

variable "fluentbit_gke" {
  description = "Fluentbit-gke exclusion for failed to parse time"
  type        = string
  default     = <<EOT
resource.labels.container_name="fluentbit-gke" AND
jsonPayload.message=~"Failed to parse time"
EOT
}

variable "fpm" {
  description = "FPM exclusion"
  type        = string
  default     = <<EOT
resource.type="container" AND
"fpm" AND
(
  ( trace:* sample(trace, 0.5) ) OR
  ( NOT trace:* operation.id:* sample(operation.id, 0.5) ) OR
  ( NOT trace:* NOT operation.id:* sample(insertId, 0.5) )
)
EOT
}

variable "custom_exclusions" {
  description = "Map of custom exclusion filters with their descriptions. The map key is used as the GCP exclusion name. Each value must include `filter` and `description`, and may optionally set `enabled` (defaults to `true`), which maps to `disabled = !enabled` on the GCP resource."
  type = map(object({
    filter      = string
    description = string
    enabled     = optional(bool, true)
  }))
  default = {}

  validation {
    condition = length(setintersection(
      toset(keys(var.custom_exclusions)),
      toset([
        "health-probe-exclusion",
        "default-k8s-exclusion",
        "gke-metadata-server-exclusion-sync-sandbox",
        "fluentbit-gke-parse-time",
        "fpm-exclusion",
        "k8s-node-system-noise",
      ])
    )) == 0
    error_message = "custom_exclusions keys must not use module-reserved exclusion names: health-probe-exclusion, default-k8s-exclusion, gke-metadata-server-exclusion-sync-sandbox, fluentbit-gke-parse-time, fpm-exclusion, k8s-node-system-noise."
  }
}

###########################
# K8s Log Exclusions
###########################
variable "k8s_log_exclusions" {
  description = <<-EOT
    Map of structured Kubernetes log exclusions. The map key is used as the GCP exclusion name (must be unique per project).
    Each entry generates a GCP log exclusion scoped to a Kubernetes namespace or GKE cluster, with optional
    selectors to narrow to a specific container or pod label.

    Fields:
      scope                  - "namespace" to target a single k8s namespace, "cluster" to target all namespaces in a GKE cluster.
                               WARNING: "cluster" scope silences logs for all workloads in the cluster.
      cluster_name           - Required. The GKE cluster name to scope the exclusion to.
      namespace              - Required when scope = "namespace". The Kubernetes namespace to filter.
                               Must NOT be set when scope = "cluster".
      container_name         - Optional. Narrow the exclusion to a specific container name
                               (appends resource.labels.container_name="<value>" to the filter).
      pod_label_key          - Optional. Kubernetes pod label key to filter on (e.g., "app", "app.kubernetes.io/name").
                               Must be set together with pod_label_value.
                               Generates: labels.k8s-pod/<key>="<value>".
      pod_label_value        - Optional. Value for the pod label key. Must be set together with pod_label_key.
      exclude_below_severity - Logs with severity strictly below this value are excluded. Defaults to "ERROR".
                               Valid values: DEFAULT, DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, ALERT, EMERGENCY.
      enabled                - When false, the GCP exclusion is disabled (resource persists in state but does not filter logs).
      description            - Human-readable description. Recommended: record activation date and review intent.

    Reserved names (already used by this module): health-probe-exclusion, default-k8s-exclusion,
    gke-metadata-server-exclusion-sync-sandbox, fluentbit-gke-parse-time, fpm-exclusion,
    k8s-node-system-noise.
  EOT
  type = map(object({
    scope                  = string
    cluster_name           = string
    namespace              = optional(string)
    container_name         = optional(string)
    pod_label_key          = optional(string)
    pod_label_value        = optional(string)
    exclude_below_severity = optional(string, "ERROR")
    enabled                = optional(bool, true)
    description            = optional(string, "")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.k8s_log_exclusions : contains(["namespace", "cluster"], v.scope)
    ])
    error_message = "Each k8s_log_exclusions entry's 'scope' must be either \"namespace\" or \"cluster\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.k8s_log_exclusions : contains([
        "DEFAULT", "DEBUG", "INFO", "NOTICE", "WARNING",
        "ERROR", "CRITICAL", "ALERT", "EMERGENCY"
      ], v.exclude_below_severity)
    ])
    error_message = "Each k8s_log_exclusions entry's 'exclude_below_severity' must be one of: DEFAULT, DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, ALERT, EMERGENCY."
  }

  validation {
    condition = alltrue([
      for k, v in var.k8s_log_exclusions : !contains([
        "health-probe-exclusion",
        "default-k8s-exclusion",
        "gke-metadata-server-exclusion-sync-sandbox",
        "fluentbit-gke-parse-time",
        "fpm-exclusion",
        "k8s-node-system-noise",
      ], k)
    ])
    error_message = "k8s_log_exclusions map keys must not use reserved names already managed by this module: health-probe-exclusion, default-k8s-exclusion, gke-metadata-server-exclusion-sync-sandbox, fluentbit-gke-parse-time, fpm-exclusion, k8s-node-system-noise."
  }

  validation {
    condition = alltrue([
      for k, v in var.k8s_log_exclusions :
      (v.pod_label_key == null) == (v.pod_label_value == null)
    ])
    error_message = "Each k8s_log_exclusions entry must set both 'pod_label_key' and 'pod_label_value' together, or omit both."
  }
}
