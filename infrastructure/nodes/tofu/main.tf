provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_user_id
  pm_api_token_secret = var.proxmox_user_secret
  pm_tls_insecure     = true
}

provider "talos" {}
