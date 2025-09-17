# This resource creates a firewall rule that allows traffic to the Kyverno admission webhook service, enabling the control plane to communicate with worker nodes over Kyverno’s TCP port, which by default is set to 9443.
resource "google_compute_firewall" "kyverno_admission_webhook" {
  count       = var.kyverno_firewall_rule.enable && var.kyverno_firewall_rule.network != "" && length(var.kyverno_firewall_rule.source_ranges) > 0 ? 1 : 0
  name        = coalesce(var.kyverno_firewall_rule.name, "kyverno-admission-webhook")
  network     = var.kyverno_firewall_rule.network
  description = coalesce(var.kyverno_firewall_rule.description, "Allow Kyverno admission webhook from control plane to nodes")
  direction   = coalesce(var.kyverno_firewall_rule.direction, "INGRESS")
  priority    = coalesce(var.kyverno_firewall_rule.priority, 1000)

  source_ranges = var.kyverno_firewall_rule.source_ranges

  allow {
    protocol = coalesce(var.kyverno_firewall_rule.protocol, "tcp")
    ports    = coalesce(var.kyverno_firewall_rule.ports, ["9443"])
  }
}
