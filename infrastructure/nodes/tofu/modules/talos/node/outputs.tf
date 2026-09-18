output "kubeconfig" {
  value = talos_cluster_kubeconfig.kubeconfig[0]
  precondition {
    condition     = length(talos_cluster_kubeconfig.kubeconfig) > 0
    error_message = "No kubeconfig associated with this machine"
  }
}
