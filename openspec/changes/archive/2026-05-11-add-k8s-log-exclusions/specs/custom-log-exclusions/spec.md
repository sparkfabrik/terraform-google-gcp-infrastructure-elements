## MODIFIED Requirements

### Requirement: custom_exclusions entries support an enabled toggle
Each entry in the `custom_exclusions` map SHALL include an `enabled` boolean field. When `enabled = false`, the GCP exclusion resource SHALL be set to `disabled = true` — the resource persists in Terraform state but does not filter any logs. The field SHALL default to `true` so existing callers are unaffected.

#### Scenario: enabled = true activates filtering (default)
- **WHEN** an entry has `enabled = true` or `enabled` is not specified
- **THEN** the GCP exclusion resource SHALL have `disabled = false` and SHALL actively filter matching logs

#### Scenario: enabled = false deactivates without destroying
- **WHEN** an entry has `enabled = false`
- **THEN** the GCP exclusion resource SHALL have `disabled = true`, SHALL NOT filter any logs, and SHALL remain in Terraform state

#### Scenario: Toggling enabled does not recreate the resource
- **WHEN** `enabled` is changed from `true` to `false` (or vice versa)
- **THEN** `terraform plan` SHALL show an in-place update, not a destroy/recreate

---

### Requirement: custom_exclusions resource block lives in logging_exclusions.tf
The `google_logging_project_exclusion` resource for `custom_exclusions` SHALL be defined in `logging_exclusions.tf`, not in `ssl.tf`.

#### Scenario: Resource file location
- **WHEN** a developer inspects `logging_exclusions.tf`
- **THEN** all `google_logging_project_exclusion` resources — including `custom_exclusions` — SHALL be present in that file

#### Scenario: ssl.tf contains no logging resources
- **WHEN** a developer inspects `ssl.tf`
- **THEN** it SHALL contain only SSL policy resources and no `google_logging_project_exclusion` resources
