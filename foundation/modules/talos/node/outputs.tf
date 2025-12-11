output "kubeconfig" {
  value = length(talos_cluster_kubeconfig.kubeconfig) > 0 ? talos_cluster_kubeconfig.kubeconfig[0].kubeconfig_raw : null
}
