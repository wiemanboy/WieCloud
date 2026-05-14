terraform {
  backend "kubernetes" {
    secret_suffix     = "state"
    in_cluster_config = true
  }
}

output "out" {
  value = "Hello World"
}
