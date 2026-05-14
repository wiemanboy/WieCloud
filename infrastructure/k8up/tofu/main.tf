terraform {
  backend "kubernetes" {
    secret_suffix     = "state"
    in_cluster_config = true
    namespace         = var.namespace
  }
}

output "out" {
  value = "Hello World"
}
