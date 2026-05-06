# ============================================
# NGINX - Reverse Proxy
# ============================================

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

resource "docker_container" "nginx" {
  name    = "${local.project}-nginx"
  image   = docker_image.nginx.image_id
  restart = "unless-stopped"

  ports {
    internal = 80
    external = 8080
  }

  volumes {
    host_path      = abspath("${path.module}/../nginx/nginx.conf")
    container_path = "/etc/nginx/nginx.conf"
    read_only      = true
  }

  healthcheck {
    test     = ["CMD", "curl", "-f", "http://localhost/health"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
  }

  networks_advanced {
    name    = docker_network.devops_network.name
    aliases = ["nginx"]
  }

  depends_on = [module.apps]
}

# ============================================
# NGINX EXPORTER - Métricas Prometheus
# ============================================

resource "docker_image" "nginx_exporter" {
  name         = "nginx/nginx-prometheus-exporter:1.2.0"
  keep_locally = true
}

resource "docker_container" "nginx_exporter" {
  name    = "${local.project}-nginx-exporter"
  image   = docker_image.nginx_exporter.image_id
  restart = "unless-stopped"
  command = ["-nginx.scrape-uri=http://nginx:80/metrics"]

  ports {
    internal = 9113
    external = 9113
  }

  networks_advanced {
    name    = docker_network.devops_network.name
    aliases = ["nginx-exporter"]
  }

  depends_on = [docker_container.nginx]
}
