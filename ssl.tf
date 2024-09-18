resource "google_compute_ssl_policy" "modern_tls_1_2" {
  name            = "modern-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}