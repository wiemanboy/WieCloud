module "talos_image" {
  source        = "./modules/talos/image"
  talos_version = "v1.11.5"
}

resource "proxmox_storage_iso" "omen-pve-0-metal-amd64-iso" {
  pve_node = "omen-pve-0"
  storage  = "local"
  filename = "metal-amd64.iso"
  url      = "https://factory.talos.dev/image/${module.talos_image.id}/${module.talos_image.talos_version}/metal-amd64.iso"
}

locals {
  node_module_source = "./modules/node"
  cluster            = "homelab-test"
  talos_version      = "v1.11.5"
  iso                = "${proxmox_storage_iso.omen-pve-0-metal-amd64-iso.storage}:iso/${proxmox_storage_iso.omen-pve-0-metal-amd64-iso.filename}"
  image              = "factory.talos.dev/installer/${module.talos_image.id}:${module.talos_image.talos_version}"
}

module "talos-controlplane-0" {
  source   = local.node_module_source
  name     = "talos-controlplane-0"
  node     = "omen-pve-0"
  endpoint = "192.168.178.47"
  cluster  = local.cluster
  role     = "controlplane"

  ip      = "192.168.178.47"
  macaddr = "BC:24:11:CE:8D:AC"

  talos_version = local.talos_version
  iso           = local.iso
  image         = local.image
}

module "talos-worker-0" {
  source   = local.node_module_source
  name     = "talos-worker-0"
  node     = "omen-pve-0"
  endpoint = "192.168.178.47"
  cluster  = local.cluster
  role     = "worker"

  ip      = "192.168.178.48"
  macaddr = "BC:24:11:E8:B7:F5"

  talos_version = local.talos_version
  iso           = local.iso
  image         = local.image
}