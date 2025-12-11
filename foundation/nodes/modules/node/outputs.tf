output "kubeconfig" {
  value = module.talos_node.kubeconfig
}

output "cluster" {
  value = var.cluster
}
output "ip" {
  value = var.ip
}
