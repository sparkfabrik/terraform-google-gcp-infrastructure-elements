## MODIFIED Requirements

### Requirement: Module accepts structured k8s log exclusion definitions
The module SHALL accept a `k8s_log_exclusions` variable of type `map(object(...))` where each entry defines a GCP log exclusion scoped to a Kubernetes namespace or GKE cluster. The object SHALL include three additional optional fields: `container_name`, `pod_label_key`, and `pod_label_value`. The map key SHALL be used as the GCP exclusion resource name.

#### Scenario: Entry with container_name generates container-scoped filter
- **WHEN** `scope = "namespace"` and `namespace = "typesense-clusters-stage"` and `container_name = "typesense"` and `exclude_below_severity = "ERROR"`
- **THEN** the generated filter SHALL be:
  ```
  resource.type="k8s_container" AND
  resource.labels.namespace_name="typesense-clusters-stage" AND
  resource.labels.container_name="typesense" AND
  severity<"ERROR"
  ```

#### Scenario: Entry with pod label generates pod-label-scoped filter
- **WHEN** `scope = "namespace"` and `namespace = "typesense-clusters-stage"` and `pod_label_key = "app"` and `pod_label_value = "typesense"` and `exclude_below_severity = "ERROR"`
- **THEN** the generated filter SHALL be:
  ```
  resource.type="k8s_container" AND
  resource.labels.namespace_name="typesense-clusters-stage" AND
  labels.k8s-pod/app="typesense" AND
  severity<"ERROR"
  ```

#### Scenario: Entry with both container_name and pod label
- **WHEN** `scope = "namespace"` and `namespace = "my-ns"` and `container_name = "web"` and `pod_label_key = "app.kubernetes.io/name"` and `pod_label_value = "my-app"` and `exclude_below_severity = "WARNING"`
- **THEN** the generated filter SHALL include all clauses: `resource.labels.namespace_name`, `resource.labels.container_name`, `labels.k8s-pod/...`, and `severity<`

#### Scenario: Entry without selectors (backward compatible)
- **WHEN** `container_name`, `pod_label_key`, and `pod_label_value` are all null (omitted)
- **THEN** the generated filter SHALL be identical to the previous behaviour (scope + severity only)

#### Scenario: Cluster scope with container_name
- **WHEN** `scope = "cluster"` and `cluster_name = "dev-cluster"` and `container_name = "nginx"` and `exclude_below_severity = "ERROR"`
- **THEN** the generated filter SHALL include `resource.labels.cluster_name="dev-cluster"` AND `resource.labels.container_name="nginx"` AND `severity<"ERROR"`

---

### Requirement: pod_label_key and pod_label_value must be paired
The module SHALL validate that `pod_label_key` and `pod_label_value` are either both set (non-null, non-empty) or both null. Setting only one SHALL produce a Terraform validation error.

#### Scenario: Only pod_label_key is set
- **WHEN** `pod_label_key = "app"` and `pod_label_value` is null
- **THEN** Terraform validation SHALL fail with a clear error indicating both must be set together

#### Scenario: Only pod_label_value is set
- **WHEN** `pod_label_key` is null and `pod_label_value = "typesense"`
- **THEN** Terraform validation SHALL fail with a clear error indicating both must be set together

#### Scenario: Both set
- **WHEN** `pod_label_key = "app"` and `pod_label_value = "typesense"`
- **THEN** validation SHALL pass
