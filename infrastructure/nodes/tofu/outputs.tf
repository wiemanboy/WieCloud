output "kubeconfig" {
  value     = module.talos_controlplane_000.kubeconfig.kubeconfig_raw
  sensitive = true
}

output "talosconfig" {
  value = yamlencode({
    context = module.talos_controlplane_000
    contexts = {
      "${module.talos_controlplane_000.cluster}" = {
        endpoints = [module.talos_controlplane_000.ip]
        ca        = talos_machine_secrets.wiecloud_machine_secret.client_configuration.ca_certificate
        crt       = talos_machine_secrets.wiecloud_machine_secret.client_configuration.client_certificate
        key       = talos_machine_secrets.wiecloud_machine_secret.client_configuration.client_key
      }
    }
  })
  sensitive = true
}
