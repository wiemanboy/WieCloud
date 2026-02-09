variable "env_file" {
  description = "Path to YAML configuration file"
  type        = string
  default     = "../../env.yaml"
}

variable "values_file" {
  description = "Path to values.yaml"
  type        = string
  default     = "../../wiecloud/chart/values.yaml"
}

locals {
  env    = yamldecode(file(var.env_file))
  values = yamldecode(file(var.values_file))
}

provider "kubernetes" {
  config_path = "../config/kubeconfig"
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = local.env.wiecloud.keycloak.admin.username
  password  = local.env.wiecloud.keycloak.admin.password
  url       = "https://keycloak.${local.values.environment.hostname}"
}

provider "random" {}
