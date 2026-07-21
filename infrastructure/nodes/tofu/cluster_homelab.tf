locals {
  homelab_cluster                        = "homelab"
  homelab_talos_version                  = "v1.11.5"
  homelab_image                          = "factory.talos.dev/installer/${module.homelab_talos_image.id}:${module.homelab_talos_image.talos_version}"
  homelab_gigabyte-pve-0-metal-amd64-iso = "${proxmox_storage_iso.homelab_gigabyte-pve-0-metal-amd64-iso.storage}:iso/${proxmox_storage_iso.homelab_gigabyte-pve-0-metal-amd64-iso.filename}"
  homelab_omen-pve-0-metal-amd64-iso     = "${proxmox_storage_iso.homelab_omen-pve-0-metal-amd64-iso.storage}:iso/${proxmox_storage_iso.homelab_omen-pve-0-metal-amd64-iso.filename}"
}

module "homelab_talos_image" {
  source        = "./modules/talos/image_factory"
  talos_version = local.homelab_talos_version
}

resource "proxmox_storage_iso" "homelab_gigabyte-pve-0-metal-amd64-iso" {
  pve_node = "gigabyte-pve-0"
  storage  = "local"
  filename = "metal-amd64.iso"
  url      = "https://factory.talos.dev/image/${module.homelab_talos_image.id}/${module.homelab_talos_image.talos_version}/metal-amd64.iso"
}

resource "proxmox_storage_iso" "homelab_omen-pve-0-metal-amd64-iso" {
  pve_node = "omen-pve-0"
  storage  = "local"
  filename = "metal-amd64.iso"
  url      = "https://factory.talos.dev/image/${module.homelab_talos_image.id}/${module.homelab_talos_image.talos_version}/metal-amd64.iso"
}

resource "talos_machine_secrets" "homelab_machine_secret" {
  talos_version = local.homelab_talos_version
  lifecycle {
    prevent_destroy = true
  }
}

module "homelab-talos-controlplane-0" {
  source   = "./modules/node"
  name     = "talos-controlplane-0"
  host     = "gigabyte-pve-0"
  zone     = "gigabyte-pve-0"
  region   = "home"
  endpoint = module.homelab-talos-controlplane-0.ip
  cluster  = local.homelab_cluster
  role     = "controlplane"

  ip      = "192.168.178.50"
  macaddr = "BC:24:11:B7:11:94"

  machine_secret = talos_machine_secrets.homelab_machine_secret
  talos_version  = local.homelab_talos_version
  iso            = local.homelab_gigabyte-pve-0-metal-amd64-iso
  image          = local.homelab_image
  bootstrap      = true

  spec = {
    cpu_cores = 4
    disk_size = 100
    memory    = 6144
  }

  oidc = {
    issuer_url = var.oidc_issuer_url
  }
}

module "homelab-talos-worker-0" {
  depends_on = [module.homelab-talos-controlplane-0]
  source     = "./modules/node"

  name     = "talos-worker-0"
  host     = "gigabyte-pve-0"
  zone     = "gigabyte-pve-0"
  region   = "home"
  endpoint = module.homelab-talos-controlplane-0.ip
  cluster  = local.homelab_cluster
  role     = "worker"

  ip      = "192.168.178.201"
  macaddr = "BC:24:11:CE:8D:AC"

  machine_secret = talos_machine_secrets.homelab_machine_secret
  talos_version  = local.homelab_talos_version
  iso            = local.homelab_gigabyte-pve-0-metal-amd64-iso
  image          = local.homelab_image

  spec = {
    cpu_cores = 8
    disk_size = 800
    memory    = 32768
  }
}

module "homelab-talos-worker-1" {
  depends_on = [module.homelab-talos-controlplane-0]
  source     = "./modules/node"

  name     = "talos-worker-1"
  host     = "omen-pve-0"
  zone     = "omen-pve-0"
  region   = "home"
  endpoint = module.homelab-talos-controlplane-0.ip
  cluster  = local.homelab_cluster
  role     = "worker"

  ip      = "192.168.178.41"
  macaddr = "BC:24:11:D1:76:E5"
  disk    = "disk-1tb-0"

  machine_secret = talos_machine_secrets.homelab_machine_secret
  talos_version  = local.homelab_talos_version
  iso            = local.homelab_omen-pve-0-metal-amd64-iso
  image          = local.homelab_image

  spec = {
    cpu_cores = 8
    disk_size = 900
    memory    = 7168
  }
}

module "homelab-talos-worker-2" {
  depends_on = [module.homelab-talos-controlplane-0]
  source     = "./modules/node"

  name     = "talos-worker-2"
  host     = "omen-pve-0"
  zone     = "omen-pve-0"
  region   = "home"
  endpoint = module.homelab-talos-controlplane-0.ip
  cluster  = local.homelab_cluster
  role     = "worker"

  ip      = "192.168.178.48"
  macaddr = "BC:24:11:E8:B7:F5"
  disk    = "disk-2tb-0"

  machine_secret = talos_machine_secrets.homelab_machine_secret
  talos_version  = local.homelab_talos_version
  iso            = local.homelab_omen-pve-0-metal-amd64-iso
  image          = local.homelab_image

  spec = {
    cpu_cores = 8
    disk_size = 1800
    memory    = 9216
  }
}
