resource "docker_image" "loadgen" {
  name         = "${local.project}/loadgen:latest"
  keep_locally = true

  build {
    context    = abspath("${path.module}/../scripts")
    dockerfile = "Dockerfile"
  }

  triggers = {
    dir_sha1 = sha1(join("", [
      for f in fileset("${path.module}/../scripts", "**") :
      filesha1("${path.module}/../scripts/${f}")
    ]))
  }
}

resource "docker_container" "loadgen" {
  name    = "${local.project}-loadgen"
  image   = docker_image.loadgen.image_id
  restart = "unless-stopped"

  networks_advanced {
    name    = local.network_name
    aliases = ["loadgen"]
  }

  depends_on = [module.apps]
}
