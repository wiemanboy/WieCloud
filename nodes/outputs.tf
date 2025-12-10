output "kubeconfig" {
  value     = module.talos-controlplane-0.kubeconfig
  sensitive = true
}

output "talosconfig" {
  value = yamlencode({
    context = module.talos-controlplane-0.cluster
    contexts = {
      "${module.talos-controlplane-0.cluster}" = {
        endpoints = [module.talos-controlplane-0.ip]
        ca = talos_machine_secrets.machine_secret.client_configuration.ca_certificate
        crt = talos_machine_secrets.machine_secret.client_configuration.client_certificate
        key =  talos_machine_secrets.machine_secret.client_configuration.client_key
      }
    }
  })
  sensitive = true
}

output "machine_secret" {
  value = yamlencode(talos_machine_secrets.machine_secret)
  sensitive = true
}