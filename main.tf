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

  disk {
    source_image = "llamacuda"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {}
  }

  guest_accelerator {
    type  = var.gpu
    count = 1
  }

  scheduling {
    preemptible        = true
    automatic_restart  = false
    provisioning_model = "SPOT"

    # Apparently this can't work with managed instance groups..?
    #instance_termination_action = "DELETE"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance_group_manager" "llama" {
  name               = "llamacuda-group"
  
  base_instance_name = "llamacuda"
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.llama.id
  }

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_autoscaler" "llama" {
  name   = "llama"
  target = google_compute_instance_group_manager.llama.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60
  }

  depends_on = [ google_compute_instance_group_manager.llama ]
}

resource "google_compute_managed_ssl_certificate" "llama" {
  name = "llama"

  managed {
    domains = ["test.johnnyb.mawenzy.com"]
  }
}

resource "google_compute_global_address" "llama" {
  name = "llama"
}

resource "google_compute_url_map" "llama" {
  name            = "llama"
  default_service = google_compute_backend_service.llama.id
}

resource "google_compute_target_https_proxy" "llama" {
  name    = "llama"
  url_map = google_compute_url_map.llama.id
  ssl_certificates = [ google_compute_managed_ssl_certificate.llama.id ]
}

resource "google_compute_global_forwarding_rule" "llama" {
  name       = "llama"
  target     = google_compute_target_https_proxy.llama.id
  port_range = "443"
  ip_address = google_compute_global_address.llama.address

  depends_on = [ google_compute_instance_group_manager.llama ]
}

resource "google_compute_backend_service" "llama" {
  name        = "llama"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10

  health_checks = [google_compute_http_health_check.llama.id]

  backend {
    group = google_compute_instance_group_manager.llama.instance_group
  }
}

resource "google_compute_http_health_check" "llama" {
  name               = "llama"
  port               = 80
  request_path       = "/"
  check_interval_sec = 2
  timeout_sec        = 1
}

output "endpoint" {
  value       = google_compute_global_address.llama.address
}
