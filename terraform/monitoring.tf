# ============================================
# PROMETHEUS - Coleta de Métricas
# ============================================

resource "docker_image" "prometheus" {
  name         = "prom/prometheus:v2.48.1"
  keep_locally = true
}

resource "docker_container" "prometheus" {
  name    = "${local.project}-prometheus"
  image   = docker_image.prometheus.image_id
  restart = "unless-stopped"

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--web.console.libraries=/usr/share/prometheus/console_libraries",
    "--web.console.templates=/usr/share/prometheus/consoles",
    "--storage.tsdb.retention.time=15d",
    "--web.enable-lifecycle",
  ]

  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    host_path      = abspath("${path.module}/../monitoring/prometheus.yml")
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }

  healthcheck {
    test         = ["CMD", "wget", "--spider", "-q", "http://localhost:9090/-/healthy"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "10s"
  }

  networks_advanced {
    name    = docker_network.devops_network.name
    aliases = ["prometheus"]
  }

  depends_on = [module.apps]
}

# ============================================
# GRAFANA - Dashboards
# ============================================

resource "docker_image" "grafana" {
  name         = "grafana/grafana:10.2.3"
  keep_locally = true
}

resource "docker_container" "grafana" {
  name    = "${local.project}-grafana"
  image   = docker_image.grafana.image_id
  restart = "unless-stopped"

  ports {
    internal = 3000
    external = 3001
  }

  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
    "GF_SERVER_ROOT_URL=http://localhost:3001",
    "GF_LOG_MODE=console",
    "GF_LOG_LEVEL=info",
    "GF_PROVISIONING_DASHBOARDS_ENABLED=true",
    "GF_PROVISIONING_DATASOURCES_ENABLED=true",
    "GF_PROVISIONING_ALERTING_ENABLED=true",
  ]

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }

  volumes {
    host_path      = abspath("${path.module}/../monitoring/grafana/provisioning")
    container_path = "/etc/grafana/provisioning"
    read_only      = true
  }

  networks_advanced {
    name    = docker_network.devops_network.name
    aliases = ["grafana"]
  }

  depends_on = [docker_container.prometheus]
}
