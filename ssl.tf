resource "google_compute_ssl_policy" "modern_tls_1_2" {
  count           = var.enable_ssl_policy ? 1 : 0
  name            = "modern-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

resource "google_logging_project_exclusion" "custom_exclusions" {
  for_each = var.custom_exclusions

  project     = var.project_id
  name        = each.key
  description = each.value.description
  filter      = each.value.filter
}
