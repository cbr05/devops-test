output "url" {
  description = "URL local da aplicação"
  value       = "http://localhost:${var.port}"
}

output "container_name" {
  description = "Nome do container Docker"
  value       = docker_container.this.name
}

output "image_id" {
  description = "ID da imagem buildada"
  value       = docker_image.this.image_id
}
