variable "proxmox_api_url" {
  description = "URL of the Proxmox API"
  type        = string
}

variable "proxmox_user_id" {
  description = "User token id for the Proxmox API"
  type        = string
}

variable "proxmox_user_secret" {
  description = "User token secret for the Proxmox Api"
  type        = string
}

variable "oidc_issuer_url" {
  description = "Issuer URL for OIDC configuration of the nodes"
  type        = string
}

