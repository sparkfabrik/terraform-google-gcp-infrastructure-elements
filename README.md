# Terraform GCP Infrastructure Elements

This project is intended to gather common elements for GCP infrastructures in order to centralize security configurations and best practices.

We suggest following Terraform best practices as described in https://www.terraform-best-practices.com/code-structure.

## SSL default policy

Creates a default policy for SSL that disables unsecure ciphers and tls<1.2

## Google Cloud Logging Exclusions

Creates standard logging exclusions for Google Cloud projects.

### Features

- Creates a health probe exclusion to filter out traffic from monitoring systems
- Creates a default exclusion for common Kubernetes system logs
- Configurable list of probe user agents to exclude

### Usage

```hcl
module "logging_exclusions" {
  source = "./modules/logging-exclusions"

  project_id = var.project

  # Selectively enable or disable specific exclusions
  enable_exclusions = {
    probe_exclusion                   = true
    default_k8s_exclusion             = true
    gke_metadata_server_sync_sandbox  = false  # Disable this exclusion
  }
}
```

Note: the Kyverno firewall rule is created only when `kyverno_firewall_rule.enable = true` and both `kyverno_firewall_rule.network` and `kyverno_firewall_rule.source_ranges` are provided. If any of these conditions is not met the rule will not be created. The module validates these fields and will fail with a clear error when `enable` is true but required fields are missing.

Example (short):

```hcl
module "infrastructure_elements" {
  source     = "./"
  project_id = var.project

  kyverno_firewall_rule = {
    enable        = true
    name          = "kyverno-admission-webhook"
    network       = "projects/PROJECT/global/networks/example-vpc" # required
    source_ranges = ["10.0.0.0/28"]                                # required
    protocol      = "tcp"
    ports         = ["9443"]
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.13 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.13 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_exclusions"></a> [custom\_exclusions](#input\_custom\_exclusions) | Map of custom exclusion filters with their descriptions. The map key is used as the GCP exclusion name. Each value must include `filter` and `description`, and may optionally set `enabled` (defaults to `true`), which maps to `disabled = !enabled` on the GCP resource. | <pre>map(object({<br>    filter      = string<br>    description = string<br>    enabled     = optional(bool, true)<br>  }))</pre> | `{}` | no |
| <a name="input_default_exclusion_filter"></a> [default\_exclusion\_filter](#input\_default\_exclusion\_filter) | Filter for default log exclusion | `string` | `"resource.type=\"k8s_cluster\" AND (protoPayload.authenticationInfo.principalEmail=~\"container-engine-robot.iam.gserviceaccount.com\" OR protoPayload.authenticationInfo.principalEmail=\"system:kubestore-collector\" OR protoPayload.authenticationInfo.principalEmail=\"system:cloud-controller-manager\" OR protoPayload.authenticationInfo.principalEmail=\"system:kube-scheduler\" OR protoPayload.authenticationInfo.principalEmail=\"system:cluster-autoscaler\" OR protoPayload.authenticationInfo.principalEmail=\"system:l7-lb-controller\" OR protoPayload.authenticationInfo.principalEmail=\"system:kube-controller-manager\" OR protoPayload.authenticationInfo.principalEmail=\"system:serviceaccount:kube-system:metrics-server\" OR protoPayload.authenticationInfo.principalEmail=\"system:addon-manager\" OR protoPayload.authenticationInfo.principalEmail=\"system:vpa-recommender\" OR protoPayload.authenticationInfo.principalEmail=\"system:gke-master-healthcheck\" OR protoPayload.authenticationInfo.principalEmail=\"system:managed-certificate-controller\" OR protoPayload.authenticationInfo.principalEmail=\"system:clustermetrics\" OR protoPayload.authenticationInfo.principalEmail=\"system:pd-csi-controller\" OR protoPayload.authenticationInfo.principalEmail=\"system:konnectivity-server\" OR protoPayload.authenticationInfo.principalEmail=\"system:serviceaccount:kube-system:kube-dns-autoscaler\" OR protoPayload.authenticationInfo.principalEmail=\"system:serviceaccount:kube-system:generic-garbage-collector\" OR protoPayload.authenticationInfo.principalEmail=\"system:gke-common-webhooks\" OR protoPayload.authenticationInfo.principalEmail=\"system:serviceaccount:kube-system:resourcequota-controller\" OR protoPayload.authenticationInfo.principalEmail=\"system:serviceaccount:kube-system:konnectivity-agent-cpha\" OR protoPayload.authenticationInfo.principalEmail=\"system:serviceaccount:kube-system:persistent-volume-binder\" OR (protoPayload.authenticationInfo.principalEmail=\"system:apiserver\" AND protoPayload.methodName=\"io.k8s.core.v1.endpoints.get\") OR protoPayload.methodName=~\"watch\" OR protoPayload.methodName=~\"io.k8s.apiserver.flowcontrol\" OR protoPayload.methodName=~\"io.k8s.discovery.v1.endpointslices\" OR protoPayload.methodName=~\"io.k8s.v1.nodes.watch\" OR protoPayload.methodName=~\"io.k8s.coordination.v1.leases\" OR protoPayload.methodName=~\"io.k8s.core.v1.componentstatuses\" OR protoPayload.methodName=~\"io.k8s.autoscaling\" OR protoPayload.methodName=~\"io.k8s.metrics.v1beta1\" OR protoPayload.methodName=~\"io.k8s.authorization.v1.selfsubjectaccessreviews\" OR protoPayload.methodName=~\"io.k8s.core.v1.nodes.status.patch\" OR (protoPayload.methodName=~\"io.k8s.get\" AND protoPayload.resourceName=~\"metrics\") OR (protoPayload.methodName=~\"io.k8s.core.v1.configmaps.get\" AND protoPayload.resourceName=~\"metrics\") OR protoPayload.resourceName=\"readyz\" OR protoPayload.resourceName=\"livez\")\n"` | no |
| <a name="input_enable_exclusions"></a> [enable\_exclusions](#input\_enable\_exclusions) | Map of boolean flags to enable/disable individual exclusions. `k8s_node_system_noise` is opt-in (defaults to false): it silences node-level system logs and should be enabled on development platforms only. | `map(bool)` | <pre>{<br>  "default_k8s_exclusion": true,<br>  "fluentbit_gke": true,<br>  "fpm": true,<br>  "gke_metadata_server_sync_sandbox": true,<br>  "k8s_node_system_noise": false,<br>  "probe_exclusion": true<br>}</pre> | no |
| <a name="input_enable_ssl_policy"></a> [enable\_ssl\_policy](#input\_enable\_ssl\_policy) | Enable SSL policy creation | `bool` | `true` | no |
| <a name="input_fluentbit_gke"></a> [fluentbit\_gke](#input\_fluentbit\_gke) | Fluentbit-gke exclusion for failed to parse time | `string` | `"resource.labels.container_name=\"fluentbit-gke\" AND\njsonPayload.message=~\"Failed to parse time\"\n"` | no |
| <a name="input_fpm"></a> [fpm](#input\_fpm) | FPM exclusion | `string` | `"resource.type=\"container\" AND\n\"fpm\" AND\n(\n  ( trace:* sample(trace, 0.5) ) OR\n  ( NOT trace:* operation.id:* sample(operation.id, 0.5) ) OR\n  ( NOT trace:* NOT operation.id:* sample(insertId, 0.5) )\n)\n"` | no |
| <a name="input_gke_metadata_server_exclusion_sync_sandbox"></a> [gke\_metadata\_server\_exclusion\_sync\_sandbox](#input\_gke\_metadata\_server\_exclusion\_sync\_sandbox) | Filter for gke-metadata-server exclusion for failed to sync sandbox | `string` | `"resource.type=\"k8s_container\" AND\nseverity=INFO AND\nresource.labels.namespace_name=\"kube-system\" AND\nlabels.k8s-pod/k8s-app=\"gke-metadata-server\" AND\njsonPayload.message=~\"Unable to sync sandbox\"\n"` | no |
| <a name="input_k8s_log_exclusions"></a> [k8s\_log\_exclusions](#input\_k8s\_log\_exclusions) | Map of structured Kubernetes log exclusions. The map key is used as the GCP exclusion name (must be unique per project).<br>Each entry generates a GCP log exclusion scoped to a Kubernetes namespace or GKE cluster, with optional<br>selectors to narrow to a specific container or pod label.<br><br>Fields:<br>  scope                  - "namespace" to target a single k8s namespace, "cluster" to target all namespaces in a GKE cluster.<br>                           WARNING: "cluster" scope silences logs for all workloads in the cluster.<br>  cluster\_name           - Required. The GKE cluster name to scope the exclusion to.<br>  namespace              - Required when scope = "namespace". The Kubernetes namespace to filter.<br>                           Must NOT be set when scope = "cluster".<br>  container\_name         - Optional. Narrow the exclusion to a specific container name<br>                           (appends resource.labels.container\_name="<value>" to the filter).<br>  pod\_label\_key          - Optional. Kubernetes pod label key to filter on (e.g., "app", "app.kubernetes.io/name").<br>                           Must be set together with pod\_label\_value.<br>                           Generates: labels.k8s-pod/<key>="<value>".<br>  pod\_label\_value        - Optional. Value for the pod label key. Must be set together with pod\_label\_key.<br>  exclude\_below\_severity - Logs with severity strictly below this value are excluded. Defaults to "ERROR".<br>                           Valid values: DEFAULT, DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, ALERT, EMERGENCY.<br>  enabled                - When false, the GCP exclusion is disabled (resource persists in state but does not filter logs).<br>  description            - Human-readable description. Recommended: record activation date and review intent.<br><br>Reserved names (already used by this module): health-probe-exclusion, default-k8s-exclusion,<br>gke-metadata-server-exclusion-sync-sandbox, fluentbit-gke-parse-time, fpm-exclusion,<br>k8s-node-system-noise. | <pre>map(object({<br>    scope                  = string<br>    cluster_name           = string<br>    namespace              = optional(string)<br>    container_name         = optional(string)<br>    pod_label_key          = optional(string)<br>    pod_label_value        = optional(string)<br>    exclude_below_severity = optional(string, "ERROR")<br>    enabled                = optional(bool, true)<br>    description            = optional(string, "")<br>  }))</pre> | `{}` | no |
| <a name="input_k8s_node_system_noise_exclude_below_severity"></a> [k8s\_node\_system\_noise\_exclude\_below\_severity](#input\_k8s\_node\_system\_noise\_exclude\_below\_severity) | Entries of the k8s\_node system logs strictly below this severity are excluded when `k8s_node_system_noise` is enabled. Entries at or above this severity are always ingested. | `string` | `"WARNING"` | no |
| <a name="input_k8s_node_system_noise_logs"></a> [k8s\_node\_system\_noise\_logs](#input\_k8s\_node\_system\_noise\_logs) | Log IDs of the k8s\_node system logs excluded by the opt-in `k8s_node_system_noise` exclusion. These logs are typically written at severity DEFAULT in very high volume (kubelet alone can exceed 50M entries/week on a busy cluster) and drive Cloud Logging ingestion cost. | `list(string)` | <pre>[<br>  "kubelet",<br>  "container-runtime",<br>  "fluentbit",<br>  "gcfs-snapshotter",<br>  "gcfsd"<br>]</pre> | no |
| <a name="input_kyverno_firewall_rule"></a> [kyverno\_firewall\_rule](#input\_kyverno\_firewall\_rule) | Rule to configure the Kyverno admission webhook firewall rule | <pre>object({<br>    enable        = bool<br>    network       = string<br>    source_ranges = list(string)<br>    name          = optional(string)<br>    description   = optional(string)<br>    direction     = optional(string)<br>    priority      = optional(number)<br>    protocol      = optional(string)<br>    ports         = optional(list(string))<br>  })</pre> | <pre>{<br>  "description": "Allow Kyverno admission webhook from control plane to nodes",<br>  "direction": "INGRESS",<br>  "enable": false,<br>  "name": "kyverno-admission-webhook",<br>  "network": "",<br>  "ports": [<br>    "9443"<br>  ],<br>  "priority": 1000,<br>  "protocol": "tcp",<br>  "source_ranges": []<br>}</pre> | no |
| <a name="input_probe_user_agents"></a> [probe\_user\_agents](#input\_probe\_user\_agents) | List of probe user agents to exclude from logs | `list(string)` | <pre>[<br>  "kube-probe",<br>  "GoogleHC"<br>]</pre> | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project ID where logging exclusions will be created | `string` | n/a | yes |
| <a name="input_ssl_modern_policy_description"></a> [ssl\_modern\_policy\_description](#input\_ssl\_modern\_policy\_description) | Description for the SSL policy | `string` | `"Modern SSL policy with minimum TLS version 1.2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_exclusion_id"></a> [default\_exclusion\_id](#output\_default\_exclusion\_id) | The ID of the default exclusion resource |
| <a name="output_fluentbit_gke_exclusion_id"></a> [fluentbit\_gke\_exclusion\_id](#output\_fluentbit\_gke\_exclusion\_id) | The ID of the Fluentbit GKE exclusion resource |
| <a name="output_fpm_exclusion_id"></a> [fpm\_exclusion\_id](#output\_fpm\_exclusion\_id) | The ID of the FPM exclusion resource |
| <a name="output_gke_metadata_server_exclusion_id"></a> [gke\_metadata\_server\_exclusion\_id](#output\_gke\_metadata\_server\_exclusion\_id) | The ID of the GKE metadata server exclusion resource |
| <a name="output_k8s_log_exclusions_ids"></a> [k8s\_log\_exclusions\_ids](#output\_k8s\_log\_exclusions\_ids) | Map of k8s log exclusion names to their GCP resource IDs |
| <a name="output_probe_exclusion_filter"></a> [probe\_exclusion\_filter](#output\_probe\_exclusion\_filter) | The filter used for probe exclusions |
| <a name="output_probe_exclusion_id"></a> [probe\_exclusion\_id](#output\_probe\_exclusion\_id) | The ID of the probe exclusion resource |
| <a name="output_ssl_policy_modern_tls_1_2_id"></a> [ssl\_policy\_modern\_tls\_1\_2\_id](#output\_ssl\_policy\_modern\_tls\_1\_2\_id) | The ID of the SSL policy resource |
| <a name="output_ssl_policy_restricted_tls_1_2_id"></a> [ssl\_policy\_restricted\_tls\_1\_2\_id](#output\_ssl\_policy\_restricted\_tls\_1\_2\_id) | The ID of the SSL policy resource |

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.kyverno_admission_webhook](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_ssl_policy.modern_tls_1_2](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_policy) | resource |
| [google_compute_ssl_policy.restricted_tls_1_2](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_policy) | resource |
| [google_logging_project_exclusion.custom_exclusions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [google_logging_project_exclusion.default_exclusion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [google_logging_project_exclusion.fluentbit_gke_parse_time](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [google_logging_project_exclusion.fpm](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [google_logging_project_exclusion.gke_metadata_server_exclusion_sync_sandbox](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [google_logging_project_exclusion.k8s_log_exclusions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [google_logging_project_exclusion.k8s_node_system_noise](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [google_logging_project_exclusion.probe_exclusion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_exclusion) | resource |
| [terraform_data.validate_exclusion_keys](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Modules

No modules.

<!-- END_TF_DOCS -->
