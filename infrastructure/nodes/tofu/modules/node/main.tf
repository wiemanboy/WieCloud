module "proxmox_vm" {
  source  = "../proxmox/vm"
  name    = var.name
  node    = var.host
  iso     = var.iso
  macaddr = var.macaddr
  disk    = var.disk
  spec    = var.spec
}

module "talos_node" {
  source         = "../talos/node"
  name           = var.name
  region         = var.region
  zone           = var.zone
  endpoint       = var.endpoint
  node           = var.ip
  role           = var.role
  cluster        = var.cluster
  image          = var.image
  machine_secret = var.machine_secret
  bootstrap      = var.bootstrap
  talos_version  = var.talos_version
  oidc           = var.oidc
  extra_config   = var.extra_config
}
