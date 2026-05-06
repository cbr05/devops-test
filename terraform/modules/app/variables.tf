variable "name" {
  description = "Nome da aplicação (ex: app1)"
  type        = string
}

variable "port" {
  description = "Porta exposta pelo container"
  type        = number
}

variable "cache_ttl" {
  description = "TTL do cache Redis (segundos)"
  type        = number
}

variable "app_version" {
  description = "Versão da aplicação"
  type        = string
  default     = "1.0.0"
}

variable "project_prefix" {
  description = "Prefixo do projeto usado em nomes de recursos"
  type        = string
}

variable "build_context" {
  description = "Caminho absoluto para o contexto de build da imagem"
  type        = string
}

variable "redis_host" {
  description = "Hostname do Redis dentro da rede Docker"
  type        = string
}

variable "redis_port" {
  description = "Porta do Redis"
  type        = number
}

variable "redis_password" {
  description = "Senha do Redis"
  type        = string
  sensitive   = true
}

variable "network_name" {
  description = "Nome da rede Docker compartilhada"
  type        = string
}
