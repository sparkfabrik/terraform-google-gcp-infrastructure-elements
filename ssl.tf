resource "google_compute_ssl_policy" "modern_tls_1_2" {
  count           = var.enable_ssl_policy ? 1 : 0
  name            = "modern-ssl-policy"
  profile         = "MODERN"
  description     = var.ssl_modern_policy_description
  min_tls_version = "TLS_1_2"
}

resource "google_compute_ssl_policy" "restricted_tls_1_2" {
  count           = var.enable_ssl_policy ? 1 : 0
  name            = "restricted-ssl-policy"
  profile         = "RESTRICTED"
  description     = "Restricted SSL policy with minimum TLS version 1.2"
  min_tls_version = "TLS_1_2"
}
