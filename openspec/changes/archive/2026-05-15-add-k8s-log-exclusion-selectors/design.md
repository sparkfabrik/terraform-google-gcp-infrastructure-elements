## Context

The `k8s_log_exclusions` variable (added in the `add-k8s-log-exclusions` change) generates GCP Cloud Logging exclusion filters scoped to a namespace or cluster with a severity threshold. This works well for single-workload namespaces but is too broad for shared namespaces. This module already uses both `resource.labels.container_name` (fluentbit exclusion) and `labels.k8s-pod/<key>` (gke-metadata-server exclusion) in its existing hardcoded filters, confirming both patterns are valid in GCP filter syntax.

## Goals / Non-Goals

**Goals:**
- Add `container_name` as an optional narrowing selector to `k8s_log_exclusions`
- Add `pod_label_key` + `pod_label_value` as an optional narrowing selector
- Both selectors can be used independently or together, always combined with the existing scope (namespace/cluster)
- Validate that `pod_label_key` and `pod_label_value` are both set or both null (never one without the other)
- Preserve full backward compatibility — all new fields default to `null`

**Non-Goals:**
- Supporting multiple pod labels per entry (use multiple entries if needed)
- Regex matching on container name or label values (GCP filter `=~` syntax — use `custom_exclusions` for that)
- Changing the `scope` enum — `container_name` and `pod_label` are optional constraints, not new scopes

## Decisions

### D1: Optional selectors, not new scopes

**Decision:** `container_name` and `pod_label_key`/`pod_label_value` are optional fields within the existing object. They are additional `AND` clauses appended to the filter, not mutually exclusive scope modes.

**Rationale:** Container name and pod labels narrow an existing scope — they don't replace it. A container name alone (without namespace/cluster context) would be dangerously broad. Keeping them as optional constraints maintains the existing scope model and allows composable combinations:
- namespace only
- namespace + container_name
- namespace + pod label
- namespace + container_name + pod label
- cluster + container_name
- cluster + pod label
- cluster + container_name + pod label

**Alternative considered:** Adding `scope = "container"` and `scope = "pod_label"`. Rejected — these aren't scopes, they're selectors within a scope.

---

### D2: Pod label uses `labels.k8s-pod/<key>` syntax

**Decision:** When `pod_label_key` is set, the generated filter clause is `labels.k8s-pod/<pod_label_key>="<pod_label_value>"`.

**Rationale:** This is the documented GCP Cloud Logging filter syntax for Kubernetes pod labels, already in use in this module at `variables.tf:93` for the gke-metadata-server exclusion.

---

### D3: `pod_label_key` and `pod_label_value` must be paired

**Decision:** A validation ensures both are set or both are null. Setting only one is a Terraform validation error.

**Rationale:** A label key without a value (or vice versa) produces a broken filter. This is a straightforward invariant.

---

### D4: Filter assembly uses dynamic list

**Decision:** Instead of branching on scope with a ternary, build a base list of clauses for the scope, then conditionally append `container_name` and pod-label clauses, then join all with `AND`.

**Rationale:** Avoids a combinatorial explosion of ternary branches (2 scopes x 3 optional selectors = many branches). A dynamic list with `concat` + conditional elements is cleaner.

## Risks / Trade-offs

- **[Risk] Pod label keys with special characters** → Keys like `app.kubernetes.io/name` contain dots and slashes. These are valid in GCP filter syntax as `labels.k8s-pod/app.kubernetes.io/name="value"` — no escaping needed. Documented in the variable description.
- **[Trade-off] Single label only** → Supporting a map of labels per entry adds complexity. A single key/value pair covers the majority use case. Callers needing multiple labels can create multiple exclusion entries, or use `custom_exclusions` for arbitrary filters.
