locals {
  node_module_source = "./modules/node"
  cluster            = "homelab"
  talos_version      = "v1.11.5"
  iso                = "${proxmox_storage_iso.omen-pve-0-metal-amd64-iso.storage}:iso/${proxmox_storage_iso.omen-pve-0-metal-amd64-iso.filename}"
  image              = "factory.talos.dev/installer/${module.talos_image.id}:${module.talos_image.talos_version}"
}

module "talos_image" {
  source        = "./modules/talos/image"
  talos_version = local.talos_version
}

resource "proxmox_storage_iso" "gigabyte-pve-0-metal-amd64-iso" {
  pve_node = "gigabyte-pve-0"
  storage  = "local"
  filename = "metal-amd64.iso"
  url      = "https://factory.talos.dev/image/${module.talos_image.id}/${module.talos_image.talos_version}/metal-amd64.iso"
}

resource "proxmox_storage_iso" "omen-pve-0-metal-amd64-iso" {
  pve_node = "omen-pve-0"
  storage  = "local"
  filename = "metal-amd64.iso"
  url      = "https://factory.talos.dev/image/${module.talos_image.id}/${module.talos_image.talos_version}/metal-amd64.iso"
}

resource "talos_machine_secrets" "machine_secret" {
  talos_version = local.talos_version
  lifecycle {
    prevent_destroy = true
  }
}

module "talos-controlplane-0" {
  source   = local.node_module_source
  name     = "talos-controlplane-0"
  node     = "gigabyte-pve-0"
  endpoint = module.talos-controlplane-0.ip
  cluster  = local.cluster
  role     = "controlplane"

  ip      = "192.168.178.50"
  macaddr = "BC:24:11:B7:11:94"

  machine_secret = talos_machine_secrets.machine_secret
  talos_version  = local.talos_version
  iso            = local.iso
  image          = local.image
  bootstrap      = true
}

module "talos-worker-0" {
  depends_on = [module.talos-controlplane-0]
  source     = local.node_module_source
  name       = "talos-worker-0"
  node       = "gigabyte-pve-0"
  endpoint   = module.talos-controlplane-0.ip
  cluster    = local.cluster
  role       = "worker"

  ip      = "192.168.178.47"
  macaddr = "BC:24:11:CE:8D:AC"

  machine_secret = talos_machine_secrets.machine_secret
  talos_version  = local.talos_version
  iso            = local.iso
  image          = local.image

  spec = {
    cpu_cores = 8
    disk_size = 300
    memory    = 32768
  }
}

module "talos-worker-1" {
  depends_on = [module.talos-controlplane-0]
  source     = local.node_module_source
  name       = "talos-worker-1"
  node       = "omen-pve-0"
  endpoint   = module.talos-controlplane-0.ip
  cluster    = local.cluster
  role       = "worker"

  ip      = "192.168.178.41"
  macaddr = "BC:24:11:D1:76:E5"

  machine_secret = talos_machine_secrets.machine_secret
  talos_version  = local.talos_version
  iso            = local.iso
  image          = local.image
}

module "talos-worker-2" {
  depends_on = [module.talos-controlplane-0]
  source     = local.node_module_source
  name       = "talos-worker-2"
  node       = "omen-pve-0"
  endpoint   = module.talos-controlplane-0.ip
  cluster    = local.cluster
  role       = "worker"

  ip      = "192.168.178.48"
  macaddr = "BC:24:11:E8:B7:F5"

  machine_secret = talos_machine_secrets.machine_secret
  talos_version  = local.talos_version
  iso            = local.iso
  image          = local.image
  bootstrap      = false
}
