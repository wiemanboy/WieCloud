output "kubeconfig" {
  value = module.talos-controlplane-0.kubeconfig
  sensitive = true
}
