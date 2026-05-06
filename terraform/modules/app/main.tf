terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_image" "this" {
  name         = "${var.project_prefix}/${var.name}:latest"
  keep_locally = true

  build {
    context    = var.build_context
    dockerfile = "Dockerfile"
  }

  triggers = {
    dir_sha1 = sha1(join("", [
      for f in fileset(var.build_context, "**") :
      filesha1("${var.build_context}/${f}")
    ]))
  }
}

resource "docker_container" "this" {
  name    = "${var.project_prefix}-${var.name}"
  image   = docker_image.this.image_id
  restart = "unless-stopped"

  ports {
    internal = var.port
    external = var.port
  }

  env = [
    "REDIS_HOST=${var.redis_host}",
    "REDIS_PORT=${var.redis_port}",
    "REDIS_PASSWORD=${var.redis_password}",
    "CACHE_TTL=${var.cache_ttl}",
    "LOG_LEVEL=INFO",
    "APP_VERSION=${var.app_version}",
  ]

  healthcheck {
    test         = ["CMD", "curl", "-f", "http://localhost:${var.port}/health"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "10s"
  }

  networks_advanced {
    name    = var.network_name
    aliases = [var.name]
  }
}
