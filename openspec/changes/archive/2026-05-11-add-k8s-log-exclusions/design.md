## Context

`terraform-google-gcp-infrastructure-elements` is a shared Terraform module used across multiple GCP projects to provision common infrastructure elements: log exclusions, SSL policies, firewall rules. The `logging_exclusions.tf` file currently defines five named `google_logging_project_exclusion` resources — each with a hardcoded filter string passed as a variable — plus a `custom_exclusions` map-driven resource that lives, incorrectly, in `ssl.tf`.

The named exclusions (probe, fpm, fluentbit, etc.) use `count = 0/1` toggled via `enable_exclusions` — toggling destroys/recreates the GCP resource. The `custom_exclusions` resource uses `for_each` and accepts raw filter strings, but has no `enabled` field, meaning disabling a custom exclusion requires removing it from the map and destroying the resource.

Projects running Typesense on GKE need a way to suppress high-volume INFO/WARNING logs from specific namespaces without writing raw GCP filter expressions and without losing the resource on toggle.

## Goals / Non-Goals

**Goals:**
- Add `k8s_log_exclusions`: a `map(object(...))` variable that accepts structured inputs (scope, namespace/cluster_name, exclude_below_severity, enabled) and generates GCP filter expressions internally
- Support `scope = "namespace"` (filters by `resource.labels.namespace_name`) and `scope = "cluster"` (filters by `resource.labels.cluster_name`)
- Use `disabled = !var.enabled` semantics: the GCP resource persists in Terraform state when `enabled = false`, no destroy/recreate cycle on toggle
- Fix `custom_exclusions`: add `enabled` field with same `disabled = !enabled` semantics
- Relocate the `custom_exclusions` resource block from `ssl.tf` to `logging_exclusions.tf`
- Add a `k8s_log_exclusions_ids` output (map of exclusion name → GCP resource ID)
- Update examples to demonstrate both capabilities

**Non-Goals:**
- Changing the existing named exclusions (probe, fpm, etc.) or their toggle mechanism
- Supporting pod-level or container-level scoping (namespace and cluster only)
- Time-based automatic expiry (not supported by GCP API)
- Replacing `custom_exclusions` — it remains for arbitrary filter strings

## Decisions

### D1: `k8s_log_exclusions` as `map(object(...))` with `for_each`

**Decision:** Use a `map(object(...))` variable where the map key becomes the GCP exclusion name. Resource addressing uses `google_logging_project_exclusion.k8s_log_exclusions[key]`.

**Rationale:** Map keys give stable Terraform resource addresses. Removing one entry only destroys that resource — no index shifting as with `list`. Map key = GCP exclusion name keeps naming explicit and under caller control.

**Alternative considered:** A `list(object(...))` with a `name` field inside each object. Rejected — list indexing is fragile; adding/removing entries in the middle shifts all subsequent resource addresses.

---

### D2: `enabled` maps to `disabled = !enabled` (resource persists when inactive)

**Decision:** Both `k8s_log_exclusions` entries and `custom_exclusions` entries expose `enabled = bool`. Internally this sets `disabled = !each.value.enabled` on the GCP resource. The resource is always created; toggling `enabled` only changes GCP's `disabled` flag.

**Rationale:** Consistent with the luiss `log_filter` module design. For incident response scenarios (e.g., a Typesense Raft storm), operators toggle `enabled = true` and apply — no resource recreation, minimal blast radius. The existing named exclusions use `count = 0/1`, which is fine for static infrastructure but awkward for operational toggles.

**Alternative considered:** Keep `count = 0/1` for `k8s_log_exclusions` consistent with existing named exclusions. Rejected — for namespace-scoped severity filters, toggle-without-destroy is the key operational requirement (it was the explicit motivation in the luiss incident).

---

### D3: Filter expression generated internally, not accepted as input

**Decision:** Callers pass `scope`, `namespace`/`cluster_name`, and `exclude_below_severity`. The module generates the GCP filter string:

```
# scope = "namespace"
resource.type="k8s_container"
resource.labels.namespace_name="<namespace>"
severity<"<exclude_below_severity>"

# scope = "cluster"
resource.type="k8s_container"
resource.labels.cluster_name="<cluster_name>"
severity<"<exclude_below_severity>"
```

**Rationale:** Callers should not need to know GCP filter syntax. The pattern is fixed and validated — generating it internally prevents typos and ensures consistent structure. `custom_exclusions` remains the escape hatch for arbitrary filters.

---

### D4: Validation via `variable` block `validation` + `precondition` lifecycle

**Decision:** `exclude_below_severity` is validated via a `variable` validation block (allowlist of GCP severity names). The `scope`/`namespace`/`cluster_name` consistency check (namespace required when scope=namespace, cluster_name required when scope=cluster) uses a `precondition` in a `lifecycle` block on the resource, same pattern as the luiss module.

**Rationale:** Variable-level validation catches bad `exclude_below_severity` at `terraform validate`. Preconditions catch the cross-variable constraint at plan time with a clear error message. Both fail early before any GCP API calls.

---

### D5: `custom_exclusions` breaking change is minor and opt-in

**Decision:** Add `enabled = bool` with `default = true` to the `custom_exclusions` object. Existing callers who pass `custom_exclusions` will have their exclusions remain active (default `true`). No action required for callers using the default `{}`.

**Rationale:** `default = true` means existing entries stay active without any change. Callers explicitly using `custom_exclusions` need to add `enabled = true` only if they want to be explicit — it will already be the default.

## Risks / Trade-offs

- **[Risk] `k8s_log_exclusions` name collision with existing named exclusions** → GCP exclusion names must be unique per project. If a caller picks a key like `"health-probe-exclusion"` (already used by the named probe resource), `terraform apply` will fail. Mitigated by documenting reserved names in the variable description.
- **[Risk] Cluster-scope exclusion silences all workloads in the cluster** → Documented in the `scope` variable description with an explicit warning. Namespace scope is the default.
- **[Risk] No automatic re-enablement** → GCP has no TTL on exclusions. An exclusion left enabled indefinitely silences logs permanently. Mitigated by the `description` field — callers should record activation date and review intent there.
- **[Trade-off] `disabled = !enabled` vs `count = 0/1`** → The new `k8s_log_exclusions` and fixed `custom_exclusions` use a different toggle mechanism than the five existing named exclusions. This is intentional (operational vs. structural exclusions) but means the module has two patterns. The divergence is acceptable given the different use cases.

## Migration Plan

1. Update `variables.tf`: add `k8s_log_exclusions`; update `custom_exclusions` object shape
2. Update `logging_exclusions.tf`: add `k8s_log_exclusions` resource; move `custom_exclusions` resource here
3. Update `ssl.tf`: remove the misplaced `custom_exclusions` resource block
4. Update `outputs.tf`: add `k8s_log_exclusions_ids` output
5. Update `examples/main.tf`: add usage examples for both variables
6. Update `README.md` via `terraform-docs` (if applicable via Makefile)
7. Run `make` / `just qa` to validate formatting and lint

**Rollback:** Remove `k8s_log_exclusions` entries and re-apply. Resources are destroyed. The `custom_exclusions` change is backward-compatible (default `enabled = true`).
