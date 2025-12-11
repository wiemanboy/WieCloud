variable "env_file" {
  description = "Path to YAML configuration file"
  type        = string
  default     = "../../env.yaml"
}

locals {
  env = yamldecode(file(var.env_file))
}

provider "kubernetes" {
    config_path = "../config/kubeconfig"
}

provider "helm" {
    kubernetes = {
      config_path = "../config/kubeconfig"
    }
}

provider "random" {}
