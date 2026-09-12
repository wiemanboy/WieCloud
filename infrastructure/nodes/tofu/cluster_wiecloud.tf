locals {
  cluster                    = "wiecloud"
  talos_version              = "v1.13.5"
  image                      = "factory.talos.dev/installer/${module.talos_image.id}:${module.talos_image.talos_version}"
  dell-pve-0-metal-amd64-iso = "${proxmox_storage_iso.dell-pve-0-metal-amd64-iso.storage}:iso/${proxmox_storage_iso.dell-pve-0-metal-amd64-iso.filename}"
}

module "talos_image" {
  source        = "./modules/talos/image_factory"
  talos_version = local.talos_version
}

resource "proxmox_storage_iso" "dell-pve-0-metal-amd64-iso" {
  pve_node = "dell-pve-0"
  storage  = "local"
  filename = "metal-amd64.iso"
  url      = "https://factory.talos.dev/image/${module.talos_image.id}/${module.talos_image.talos_version}/metal-amd64.iso"
}

resource "talos_machine_secrets" "wiecloud_machine_secret" {
  talos_version = local.talos_version
  lifecycle {
    prevent_destroy = true
  }
}

module "talos-controlplane-0" {
  source = "./modules/node"

  name   = "talos-controlplane-000"
  host   = "dell-pve-000"
  rack   = "aurora-rack-000"

  endpoint = module.talos-controlplane-0.ip
  cluster  = local.cluster
  role     = "controlplane"

  ip      = "192.168.178.50"
  macaddr = "BC:24:11:B7:11:94"

  machine_secret = talos_machine_secrets.wiecloud_machine_secret
  talos_version  = local.talos_version
  iso            = local.dell-pve-0-metal-amd64-iso
  image          = local.image
  bootstrap      = true

  spec = {
    cpu_cores = 4
    disk_size = 20
    memory    = 6144
  }

  oidc = {
    issuer_url = var.oidc_issuer_url
  }
}

module "talos-worker-0" {
  depends_on = [module.talos-controlplane-0]
  source     = "./modules/node"

  name   = "talos-worker-000"
  host   = "dell-pve-000"
  rack   = "aurora-rack-000"

  endpoint = module.talos-controlplane-0.ip
  cluster  = local.cluster
  role     = "worker"

  ip      = "192.168.178.201"
  macaddr = "BC:24:11:CE:8D:AC"

  machine_secret = talos_machine_secrets.machine_secret
  talos_version  = local.talos_version
  iso            = local.dell-pve-0-metal-amd64-iso
  image          = local.image

  spec = {
    cpu_cores = 8
    disk_size = 200
    memory    = 12288
  }
}

