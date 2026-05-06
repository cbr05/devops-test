output "app_urls" {
  description = "URLs de todas as aplicações"
  value       = { for name, mod in module.apps : name => mod.url }
}

output "nginx_url" {
  description = "URL do Nginx (reverse proxy)"
  value       = "http://localhost:8080"
}

output "prometheus_url" {
  description = "URL do Prometheus"
  value       = "http://localhost:9090"
}

output "grafana_url" {
  description = "URL do Grafana"
  value       = "http://localhost:3001"
}

output "redis_exporter_url" {
  description = "URL do Redis Exporter"
  value       = "http://localhost:9121/metrics"
}
