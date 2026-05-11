## 1. Add k8s_log_exclusions variable

- [x] 1.1 Add `k8s_log_exclusions` variable to `variables.tf` as `map(object({ scope, namespace, cluster_name, exclude_below_severity, enabled, description }))` with validations on `scope` and `exclude_below_severity`, defaulting to `{}`

## 2. Implement k8s_log_exclusions resource in logging_exclusions.tf

- [x] 2.1 Add `locals` block to `logging_exclusions.tf` that computes the filter expression per entry based on `scope` (namespace vs cluster) and `exclude_below_severity`
- [x] 2.2 Add `google_logging_project_exclusion` resource using `for_each = var.k8s_log_exclusions` with `disabled = !each.value.enabled` and `filter = local.k8s_log_exclusion_filters[each.key]`
- [x] 2.3 Add `precondition` lifecycle blocks to validate namespace/cluster_name are set when their respective scope is selected

## 3. Fix custom_exclusions

- [x] 3.1 Update `custom_exclusions` object type in `variables.tf` to add `enabled = optional(bool, true)` field
- [x] 3.2 Move `google_logging_project_exclusion.custom_exclusions` resource block from `ssl.tf` to `logging_exclusions.tf`
- [x] 3.3 Update the resource to use `disabled = !each.value.enabled`
- [x] 3.4 Remove the `custom_exclusions` resource block from `ssl.tf`

## 4. Update outputs

- [x] 4.1 Add `k8s_log_exclusions_ids` output to `outputs.tf` as `{ for k, v in google_logging_project_exclusion.k8s_log_exclusions : k => v.id }`

## 5. Update examples

- [x] 5.1 Add a `k8s_log_exclusions` example to `examples/main.tf` showing a namespace-scoped entry (e.g., a Typesense namespace) with `enabled = true` and a cluster-scoped entry with `enabled = false`
- [x] 5.2 Add a `custom_exclusions` example to `examples/main.tf` demonstrating the `enabled` field

## 6. Validate

- [x] 6.1 Run `terraform fmt -recursive` and fix any formatting issues
- [x] 6.2 Run `terraform validate` (or `make` / `just qa`) and fix any errors
