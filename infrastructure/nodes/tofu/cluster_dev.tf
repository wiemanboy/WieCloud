locals {
  dev_cluster                = "dev"
  dev_talos_version          = "v1.11.5"
  dev_image                  = "factory.talos.dev/installer/${module.dev_talos_image.id}:${module.dev_talos_image.talos_version}"
  dell_pve_0_metal_amd64_iso = "${proxmox_storage_iso.dell_pve_0_metal_amd64_iso.storage}:iso/${proxmox_storage_iso.dell_pve_0_metal_amd64_iso.filename}"
  dev_cilium_config = {
    cluster = {
      network = {
        cni = {
          name = "none"
        }
      }
      proxy = {
        disabled = true
      }
    }
  }
}

module "dev_talos_image" {
  source        = "./modules/talos/image_factory"
  talos_version = local.dev_talos_version
}

resource "proxmox_storage_iso" "dell_pve_0_metal_amd64_iso" {
  pve_node = "dell-pve-0"
  storage  = "local"
  filename = "metal-amd64.iso"
  url      = "https://factory.talos.dev/image/${module.dev_talos_image.id}/${module.dev_talos_image.talos_version}/metal-amd64.iso"
}

resource "talos_machine_secrets" "dev_machine_secret" {
  talos_version = local.dev_talos_version
  lifecycle {
    prevent_destroy = true
  }
}

module "dev_talos_controlplane_0" {
  source   = "./modules/node"
  name     = "talos-controlplane-0"
  node     = "dell-pve-0"
  region   = "nl-central-0"
  endpoint = module.dev_talos_controlplane_0.ip
  cluster  = local.dev_cluster
  role     = "controlplane"

  ip      = "192.168.178.210"
  macaddr = "AA:00:FF:E2:AF:FD"

  machine_secret = talos_machine_secrets.dev_machine_secret
  talos_version  = local.dev_talos_version
  iso            = local.dell_pve_0_metal_amd64_iso
  image          = local.dev_image
  bootstrap      = true

  spec = {
    cpu_cores = 6
    disk_size = 50
    memory    = 8192
  }

  oidc = {
    issuer_url = var.oidc_issuer_url
  }

  extra_config = local.dev_cilium_config
}

module "dev_talos_worker_0" {
  depends_on = [module.dev_talos_controlplane_0]
  source     = "./modules/node"

  name     = "talos-worker-0"
  node     = "dell-pve-0"
  region   = "nl-central-0"
  endpoint = module.dev_talos_controlplane_0.ip
  cluster  = local.dev_cluster
  role     = "worker"

  ip      = "192.168.178.211"
  macaddr = "AA:00:FF:85:16:26"

  machine_secret = talos_machine_secrets.dev_machine_secret
  talos_version  = local.dev_talos_version
  iso            = local.dell_pve_0_metal_amd64_iso
  image          = local.dev_image

  spec = {
    cpu_cores = 8
    disk_size = 100
    memory    = 16384
  }

  extra_config = local.dev_cilium_config
}
