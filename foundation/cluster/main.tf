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

provider "keycloak" {
  client_id = "admin-cli"
  username  = local.env.wiecloud.keycloak.admin.username
  password  = local.env.wiecloud.keycloak.admin.password
  url       = "https://keycloak.wieman.cloud"
}

provider "random" {}
