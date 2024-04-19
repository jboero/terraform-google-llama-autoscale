provider "google" {
  region  = var.region
  zone    = var.zone
  project = var.project_id

  default_labels = {
    owner = "john_boero"
    usage = "llama"
  }
}

resource "google_compute_instance_template" "llama" {
  name         = "llamacuda-template"
  machine_type = var.instance_type
  tags         = ["http-server", "lb-health-check"]

  disk {
    source_image = var.image
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = var.network
    subnetwork = "llama"
    // Disable external IPs ideally.
    #access_config {}
  }

  guest_accelerator {
    type  = var.gpu
    count = var.gpu_count
  }

  scheduling {
    preemptible        = true
    automatic_restart  = false
    provisioning_model = "SPOT"

    # Apparently this can't work with managed instance groups..
    # Wonder how it works with spot groups...?
    #instance_termination_action = "DELETE"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance_group_manager" "llama" {
  name = var.name

  base_instance_name = "llamacuda"
  target_size        = 1
  target_pools       = [google_compute_target_pool.llama.id]

  version {
    instance_template = google_compute_instance_template.llama.id
  }

  named_port {
    name = "http"
    port = var.port
  }
}

resource "google_compute_target_pool" "llama" {
  name = var.name
}

resource "google_compute_autoscaler" "llama" {
  name   = var.name
  target = google_compute_instance_group_manager.llama.id

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = 180
    cpu_utilization {
      target = 0.06
      #predictive_method = "OPTIMIZE_AVAILABILITY"
    }
  }

  depends_on = [google_compute_instance_group_manager.llama]
}

/** /
// For adding DNS/TLS.
data "google_dns_managed_zone" "env_dns_zone" {
  name = var.name
}

resource "google_dns_record_set" "llama" {
  name         = "llama.${data.google_dns_managed_zone.env_dns_zone.dns_name}"
  managed_zone = data.google_dns_managed_zone.env_dns_zone.name
  type         = "A"
  ttl          = 300
  rrdatas = [
    google_compute_global_forwarding_rule.llama.ip_address
  ]
}
/** /
resource "google_compute_managed_ssl_certificate" "llama" {
  name = var.name

  managed {
    domains = ["llama.${data.google_dns_managed_zone.env_dns_zone.dns_name}"]
  }
}

resource "google_compute_target_https_proxy" "llama" {
  name    = "llama"
  url_map = google_compute_url_map.llama.id
  ssl_certificates = [ google_compute_managed_ssl_certificate.llama.id ]
}
/**/

resource "google_compute_url_map" "llama" {
  name            = "llama"
  default_service = google_compute_backend_service.llama.id
}

resource "google_compute_target_http_proxy" "llama" {
  name    = "llama"
  url_map = google_compute_url_map.llama.id
}

resource "google_compute_global_forwarding_rule" "llama" {
  name       = "llama"
  #target     = google_compute_target_https_proxy.llama.id
  target     = google_compute_target_http_proxy.llama.id
  port_range = var.port

  load_balancing_scheme = var.load_balancing_scheme

  // You'll need to set ip_address if you change load balancing scheme
  #ip_address = google_compute_global_address.llama.address
}

resource "google_compute_backend_service" "llama" {
  name        = "llama"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10

  health_checks         = [google_compute_health_check.llama.id]
  load_balancing_scheme = var.load_balancing_scheme

  log_config {
    enable = true
  }

  backend {
    group = google_compute_instance_group_manager.llama.instance_group
    balancing_mode = "UTILIZATION"
  }
}

// Default health check for HTTP is fine. HOST:80/ 
resource "google_compute_health_check" "llama" {
  name = var.name

  http_health_check {
    port = var.port
  }
}

resource "google_compute_firewall" "allow_lb_health_check" {
  name    = "allow-lb-health-check"
  description = "Allow ingress from GCP LB health checks on TCP port ${var.port}"
  network = var.network
  direction = "INGRESS"
  priority = 1

  allow {
    protocol = "tcp"
    ports    = [var.port]
  }

  // Google Cloud Load Balancer IP ranges for health checks
  source_ranges = ["130.211.0.0/22",  "35.191.0.0/16", "35.191.0.0/16", 
                   "209.85.152.0/22", "209.85.204.0/22", "35.191.0.0/16", 
                   "130.211.0.0/22"]

  target_tags = ["http-server", "lb-health-check"]
}