## Why

The module currently handles log exclusions as flat, named resources with raw GCP filter strings — callers must hand-write filter expressions and have no way to disable an exclusion without destroying and recreating the GCP resource. Projects running Typesense (or any other noisy k8s workload) on GKE need a structured, reusable way to suppress low-severity logs per namespace or cluster, with a safe enable/disable toggle that keeps the resource alive in Terraform state.

## What Changes

- New `k8s_log_exclusions` variable: a map of structured objects that generate GCP log exclusions scoped to a Kubernetes namespace or GKE cluster, with configurable `exclude_below_severity` and an `enabled` toggle. Callers declare namespace/cluster + severity — the module builds the filter internally.
- Fix `custom_exclusions`: add an `enabled` boolean field to each entry (maps to `disabled = !enabled` on the GCP resource), allowing exclusions to be deactivated without destroying them.
- Move `custom_exclusions` resource block from `ssl.tf` to `logging_exclusions.tf` where it belongs.
- Update `outputs.tf` to expose a map of IDs for `k8s_log_exclusions` resources.
- Update `examples/main.tf` to demonstrate both `k8s_log_exclusions` and `custom_exclusions` usage.

## Capabilities

### New Capabilities

- `k8s-log-exclusions`: A structured, map-driven GCP log exclusion capability scoped to Kubernetes namespaces or GKE clusters. Generates filter expressions internally from `scope`, `namespace`/`cluster_name`, and `exclude_below_severity`. Supports an `enabled` toggle that disables filtering without destroying the Terraform resource.

### Modified Capabilities

- `custom-log-exclusions`: The existing `custom_exclusions` variable gains an `enabled` boolean field per entry, and its resource block is relocated to `logging_exclusions.tf`.

## Impact

- Modified file: `variables.tf` (new `k8s_log_exclusions` variable; updated `custom_exclusions` object shape)
- Modified file: `logging_exclusions.tf` (new `for_each` resource for `k8s_log_exclusions`; `custom_exclusions` resource moved here)
- Modified file: `ssl.tf` (remove misplaced `custom_exclusions` resource block)
- Modified file: `outputs.tf` (new `k8s_log_exclusions_ids` map output)
- Modified file: `examples/main.tf` (usage examples for both new and updated variables)
- **BREAKING** (minor): `custom_exclusions` object shape changes — existing callers passing `custom_exclusions` must add `enabled = true` to each entry. Default is `{}` so projects not using it are unaffected.
