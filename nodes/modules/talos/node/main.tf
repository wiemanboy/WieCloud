resource "talos_machine_secrets" "machine_secret" {}

data "talos_machine_configuration" "machine_config" {
  cluster_name     = var.cluster
  machine_type     = var.role
  cluster_endpoint = "https://${var.endpoint}:6443"
  machine_secrets  = talos_machine_secrets.machine_secret.machine_secrets
  talos_version    = var.talos_version
}

data "talos_client_configuration" "client_config" {
  cluster_name         = var.cluster
  client_configuration = talos_machine_secrets.machine_secret.client_configuration
  nodes                = [var.node]
}

resource "talos_machine_configuration_apply" "config_apply" {
  client_configuration        = talos_machine_secrets.machine_secret.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machine_config.machine_configuration
  node                        = var.node
  config_patches = [
    file("./talos/bare-metal.config.yaml"),
    file("./talos/${var.role}.config.yaml"),
    yamlencode({
      machine = {
        install = {
          image = var.image
        }
      }
    })
  ]
}

data "external" "status" {
  program = ["bash", "${path.root}/talos/check_status.sh", var.node]
}

resource "talos_machine_bootstrap" "bootstrap" {
  count                = data.external.status.result.status == "maintenance" && var.role == "controlplane" ? 1 : 0
  depends_on           = [talos_machine_configuration_apply.config_apply]
  node                 = var.node
  client_configuration = talos_machine_secrets.machine_secret.client_configuration
}

// talos_client_configuration.client_config.talos_config

resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [
    talos_machine_bootstrap.bootstrap
  ]
  count                = var.role == "controlplane" ? 1 : 0
  client_configuration = talos_machine_secrets.machine_secret.client_configuration
  node                 = var.node
}
