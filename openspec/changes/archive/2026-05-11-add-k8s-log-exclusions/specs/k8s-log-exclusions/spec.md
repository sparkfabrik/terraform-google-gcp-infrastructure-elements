## ADDED Requirements

### Requirement: Module accepts structured k8s log exclusion definitions
The module SHALL accept a `k8s_log_exclusions` variable of type `map(object(...))` where each entry defines a GCP log exclusion scoped to a Kubernetes namespace or GKE cluster. The map key SHALL be used as the GCP exclusion resource name.

#### Scenario: Map with one namespace-scoped entry
- **WHEN** `k8s_log_exclusions` contains one entry with `scope = "namespace"` and a valid `namespace`
- **THEN** exactly one `google_logging_project_exclusion` resource SHALL be created with the map key as its name

#### Scenario: Map with multiple entries
- **WHEN** `k8s_log_exclusions` contains multiple entries
- **THEN** one `google_logging_project_exclusion` resource SHALL be created per entry, independently

#### Scenario: Empty map (default)
- **WHEN** `k8s_log_exclusions` is not provided (defaults to `{}`)
- **THEN** no `google_logging_project_exclusion` resources SHALL be created by this variable

---

### Requirement: Namespace scope generates a namespace-scoped filter
When an entry has `scope = "namespace"`, the module SHALL generate a GCP log filter targeting `resource.type="k8s_container"` and `resource.labels.namespace_name` equal to the provided `namespace` value.

#### Scenario: Namespace filter structure
- **WHEN** `scope = "namespace"` and `namespace = "typesense-clusters-stage"` and `exclude_below_severity = "ERROR"`
- **THEN** the generated filter SHALL be:
  ```
  resource.type="k8s_container"
  resource.labels.namespace_name="typesense-clusters-stage"
  severity<"ERROR"
  ```

#### Scenario: namespace is required when scope is namespace
- **WHEN** `scope = "namespace"` and `namespace` is null or empty
- **THEN** Terraform SHALL fail at plan time with a clear error message indicating `namespace` is required

---

### Requirement: Cluster scope generates a cluster-scoped filter
When an entry has `scope = "cluster"`, the module SHALL generate a GCP log filter targeting `resource.type="k8s_container"` and `resource.labels.cluster_name` equal to the provided `cluster_name` value, with no `namespace_name` constraint.

#### Scenario: Cluster filter structure
- **WHEN** `scope = "cluster"` and `cluster_name = "my-gke-cluster"` and `exclude_below_severity = "WARNING"`
- **THEN** the generated filter SHALL be:
  ```
  resource.type="k8s_container"
  resource.labels.cluster_name="my-gke-cluster"
  severity<"WARNING"
  ```

#### Scenario: cluster_name is required when scope is cluster
- **WHEN** `scope = "cluster"` and `cluster_name` is null or empty
- **THEN** Terraform SHALL fail at plan time with a clear error message indicating `cluster_name` is required

---

### Requirement: exclude_below_severity controls which logs are excluded
The module SHALL exclude all log entries with severity strictly below `exclude_below_severity`. The default SHALL be `"ERROR"`. Valid values SHALL be the GCP severity names: `DEFAULT`, `DEBUG`, `INFO`, `NOTICE`, `WARNING`, `ERROR`, `CRITICAL`, `ALERT`, `EMERGENCY`.

#### Scenario: ERROR threshold (default)
- **WHEN** `exclude_below_severity` is not provided
- **THEN** the generated filter SHALL use `severity<"ERROR"`, excluding DEBUG, INFO, NOTICE, WARNING

#### Scenario: WARNING threshold
- **WHEN** `exclude_below_severity = "WARNING"`
- **THEN** the generated filter SHALL use `severity<"WARNING"`, excluding DEBUG, INFO, NOTICE

#### Scenario: Invalid severity value
- **WHEN** `exclude_below_severity` is set to a value not in the allowed list (e.g., `"VERBOSE"`)
- **THEN** Terraform validation SHALL fail with a clear error listing valid values

---

### Requirement: enabled toggle controls filtering without destroying the resource
Each entry SHALL expose an `enabled` boolean field. When `enabled = false`, the GCP exclusion resource SHALL be set to `disabled = true` — the resource exists in Terraform state but does not filter any logs. When `enabled = true`, the resource SHALL actively filter matching logs.

#### Scenario: enabled = true activates filtering
- **WHEN** an entry has `enabled = true`
- **THEN** the GCP exclusion resource SHALL have `disabled = false` and SHALL filter matching logs

#### Scenario: enabled = false deactivates without destroying
- **WHEN** an entry has `enabled = false`
- **THEN** the GCP exclusion resource SHALL have `disabled = true`, SHALL NOT filter any logs, and SHALL remain in Terraform state

#### Scenario: Toggling enabled does not recreate the resource
- **WHEN** `enabled` is changed from `true` to `false` (or vice versa)
- **THEN** `terraform plan` SHALL show an in-place update, not a destroy/recreate

---

### Requirement: Module outputs a map of k8s log exclusion resource IDs
The module SHALL expose a `k8s_log_exclusions_ids` output of type `map(string)` mapping each entry's map key to its GCP `google_logging_project_exclusion` resource ID.

#### Scenario: Output contains all enabled and disabled entries
- **WHEN** `k8s_log_exclusions` has entries with both `enabled = true` and `enabled = false`
- **THEN** `k8s_log_exclusions_ids` SHALL contain IDs for all entries regardless of enabled state

#### Scenario: Output is empty when no exclusions defined
- **WHEN** `k8s_log_exclusions` is `{}`
- **THEN** `k8s_log_exclusions_ids` SHALL be an empty map
