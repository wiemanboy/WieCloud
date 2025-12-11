variable "env_file" {
  description = "Path to YAML configuration file"
  type        = string
  default     = "../../env.yaml"
}

locals {
  env = yamldecode(file(var.env_file))
}

provider "proxmox" {
  pm_api_url          = "https://192.168.178.166:8006/api2/json"
  pm_api_token_id     = local.env.wiecloud.proxmox.user.id
  pm_api_token_secret = local.env.wiecloud.proxmox.user.secret
  pm_tls_insecure     = true
}

provider "talos" {}
