terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.5"
}

provider "docker" {}

# ============================================
# LOCALS
# ============================================

locals {
  project      = "devops-test"
  network_name = docker_network.devops_network.name
  redis_host   = "redis"
  redis_port   = 6379
}

# ============================================
# NETWORK
# ============================================

resource "docker_network" "devops_network" {
  name   = "devops-network"
  driver = "bridge"
}

# ============================================
# VOLUMES
# ============================================

resource "docker_volume" "redis_data" {
  name = "devops-test-redis-data"
}

resource "docker_volume" "prometheus_data" {
  name = "devops-test-prometheus-data"
}

resource "docker_volume" "grafana_data" {
  name = "devops-test-grafana-data"
}
