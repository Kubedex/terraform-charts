resource "null_resource" "dockerrm" {
  provisioner "local-exec" {
    command = "docker kill $(docker inspect --format={{.Id}} terraform-helmfile) && docker rm $(docker inspect --format={{.Id}} terraform-helmfile) || true"
  }
}

resource "docker_container" "helmfile" {
  name       = "terraform-helmfile"
  image      = "quay.io/roboll/helmfile:v0.80.2"
  links      = ["k3s-server"]
  entrypoint = ["/entrypoint.sh"]
  start      = true

  upload = {
    content    = "${data.template_file.entrypoint.rendered}"
    file       = "/entrypoint.sh"
    executable = true
  }

  upload = {
    content = "${data.template_file.kubeconfig.rendered}"
    file    = "/kubeconfig.yaml"
  }

  upload = {
    content = "${data.template_file.helmfile.rendered}"
    file    = "/helmfile.yaml"
  }

  depends_on = [
    "null_resource.dockerrm",
  ]
}

resource "null_resource" "dockerlogs" {
  provisioner "local-exec" {
    command = "./logtail.py $(docker inspect --format={{.Id}} terraform-helmfile)"
  }

  depends_on = [
    "docker_container.helmfile",
  ]
}
