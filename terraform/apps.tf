module "apps" {
  for_each = var.apps
  source   = "./modules/app"

  name           = each.key
  port           = each.value.port
  cache_ttl      = each.value.cache_ttl
  build_context  = abspath("${path.module}/${each.value.build_context}")
  project_prefix = local.project
  redis_host     = local.redis_host
  redis_port     = local.redis_port
  redis_password = var.redis_password
  network_name   = local.network_name

  depends_on = [docker_container.redis]
}
