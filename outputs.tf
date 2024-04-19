output "endpoint" {
  value = "http://${google_compute_global_forwarding_rule.llama.ip_address}:${var.port}"
}