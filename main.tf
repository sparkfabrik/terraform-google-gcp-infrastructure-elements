resource "google_compute_ssl_policy" "modern_tls_1_2" {
  count           = var.enable_ssl_policy ? 1 : 0
  name            = "modern-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}
