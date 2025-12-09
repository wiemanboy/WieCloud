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
    yamlencode({
      machine = {
        install = {
          image = var.image
        }
      }
    })
  ]
}

# resource "talos_machine_bootstrap" "bootstrap" {
#   depends_on           = [talos_machine_configuration_apply.config_apply]
#   node                 = var.node
#   client_configuration = talos_machine_secrets.machine_secret.client_configuration
# }
