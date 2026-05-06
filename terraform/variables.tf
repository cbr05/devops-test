variable "redis_password" {
  description = "Senha do Redis"
  type        = string
  default     = "redis123"
  sensitive   = true

  validation {
    condition     = length(var.redis_password) >= 8
    error_message = "A senha do Redis deve ter no mínimo 8 caracteres."
  }
}

variable "grafana_admin_password" {
  description = "Senha do admin do Grafana"
  type        = string
  default     = "admin123"
  sensitive   = true

  validation {
    condition     = length(var.grafana_admin_password) >= 8
    error_message = "A senha do Grafana deve ter no mínimo 8 caracteres."
  }
}

variable "apps" {
  description = "Configuração das aplicações — chave vira nome do container e alias de rede"
  type = map(object({
    port          = number
    cache_ttl     = number
    build_context = string # relativo ao diretório terraform/
  }))
  default = {
    app1 = {
      port          = 8001
      cache_ttl     = 10
      build_context = "../app1"
    }
    app2 = {
      port          = 8002
      cache_ttl     = 60
      build_context = "../app2"
    }
  }
}
