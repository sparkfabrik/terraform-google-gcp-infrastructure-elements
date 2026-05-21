## Why

The `k8s_log_exclusions` variable currently scopes exclusions to a namespace or cluster, but cannot narrow further to a specific workload. In clusters running multiple services in the same namespace, a namespace-scoped exclusion silences logs for all workloads — not just the noisy one. Adding optional `container_name` and pod-label selectors lets callers target a specific workload without affecting neighbours.

## What Changes

- Extend `k8s_log_exclusions` object type with three new optional fields: `container_name`, `pod_label_key`, and `pod_label_value`.
- Update filter generation in `logging_exclusions.tf` to conditionally append `resource.labels.container_name` and/or `labels.k8s-pod/<key>` clauses when the fields are set.
- Add validation: `pod_label_key` and `pod_label_value` must both be set or both be null.
- Update `examples/main.tf` to demonstrate the new selectors.

## Capabilities

### New Capabilities

<!-- none -->

### Modified Capabilities

- `k8s-log-exclusions`: Adds optional `container_name` and `pod_label_key`/`pod_label_value` fields that narrow the exclusion filter to a specific container or pod label within the existing namespace/cluster scope.

## Impact

- Modified file: `variables.tf` (three new optional fields in `k8s_log_exclusions` object, new validation)
- Modified file: `logging_exclusions.tf` (filter generation updated to append optional clauses)
- Modified file: `examples/main.tf` (new example entries demonstrating selectors)
- No breaking changes — new fields are all `optional` with `null` defaults; existing callers are unaffected.
