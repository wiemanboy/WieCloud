variable "env_file" {
  description = "Path to YAML configuration file"
  type        = string
  default     = "../env.yaml"
}

locals {
  env = yamldecode(file(var.env_file))
}

provider "proxmox" {
  pm_api_url          = "https://${local.env.proxmox.nodes[0].address}:8006/api2/json"
  pm_api_token_id     = local.env.proxmox.nodes[0].user.id
  pm_api_token_secret = local.env.proxmox.nodes[0].user.secret
  pm_tls_insecure     = local.env.proxmox.nodes[0].tlsInsecure
}

provider "talos" {

}
