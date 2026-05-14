## 1. Extend k8s_log_exclusions variable

- [x] 1.1 Add `container_name = optional(string)` to the `k8s_log_exclusions` object type in `variables.tf`
- [x] 1.2 Add `pod_label_key = optional(string)` and `pod_label_value = optional(string)` to the object type
- [x] 1.3 Add validation that `pod_label_key` and `pod_label_value` are both set or both null
- [x] 1.4 Update the variable description to document the new fields

## 2. Update filter generation

- [x] 2.1 Refactor `k8s_log_exclusion_filters` local in `logging_exclusions.tf` to build a dynamic clause list: base scope clauses + optional `container_name` + optional pod label + severity
- [x] 2.2 Add precondition to validate `container_name` is non-empty after trimspace when set (same pattern as namespace/cluster_name)

## 3. Update examples

- [x] 3.1 Add an example entry to `examples/main.tf` demonstrating `container_name`
- [x] 3.2 Add an example entry demonstrating `pod_label_key` + `pod_label_value`

## 4. Validate

- [x] 4.1 Run `terraform fmt -recursive` and fix any formatting issues
- [x] 4.2 Run `make lint` and fix any errors
