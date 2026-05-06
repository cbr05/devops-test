# ============================================
# REDIS - Cache Layer
# ============================================

resource "docker_image" "redis" {
  name         = "redis:7-alpine"
  keep_locally = true
}

resource "docker_container" "redis" {
  name    = "${local.project}-redis"
  image   = docker_image.redis.image_id
  restart = "unless-stopped"
  command = ["redis-server", "/usr/local/etc/redis/redis.conf"]

  ports {
    internal = 6379
    external = 6379
  }

  volumes {
    volume_name    = docker_volume.redis_data.name
    container_path = "/data"
  }

  volumes {
    host_path      = abspath("${path.module}/../redis/redis.conf")
    container_path = "/usr/local/etc/redis/redis.conf"
    read_only      = true
  }

  healthcheck {
    test     = ["CMD", "redis-cli", "-a", var.redis_password, "ping"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }

  networks_advanced {
    name    = docker_network.devops_network.name
    aliases = ["redis"]
  }
}

# ============================================
# REDIS EXPORTER - Métricas Prometheus
# ============================================

resource "docker_image" "redis_exporter" {
  name         = "oliver006/redis_exporter:v1.57.0"
  keep_locally = true
}

resource "docker_container" "redis_exporter" {
  name    = "${local.project}-redis-exporter"
  image   = docker_image.redis_exporter.image_id
  restart = "unless-stopped"

  ports {
    internal = 9121
    external = 9121
  }

  env = [
    "REDIS_ADDR=redis:6379",
    "REDIS_PASSWORD=${var.redis_password}",
  ]

  networks_advanced {
    name    = docker_network.devops_network.name
    aliases = ["redis-exporter"]
  }

  depends_on = [docker_container.redis]
}
