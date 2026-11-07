terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc06"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }
    routeros = {
      source = "terraform-routeros/routeros"
      version = "1.99.1"
    }
  }
}
