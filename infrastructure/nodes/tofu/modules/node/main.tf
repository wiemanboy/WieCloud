module "proxmox_vm" {
  source = "../proxmox/vm"
  name   = var.name
  node   = var.host
  iso    = var.iso
  disk   = var.disk
  spec   = var.spec
}

module "dhcp_lease" {
  source     = "../routeros/find_dhcp_lease"
  depends_on = [module.proxmox_vm]

  hostname = var.name
}

module "talos_node" {
  source     = "../talos/node"
  depends_on = [module.proxmox_vm, module.dhcp_lease]

  name           = var.name
  zone           = var.host
  region         = var.rack
  endpoint       = var.endpoint == null ? var.endpoint : module.dhcp_lease.data.address
  node           = module.dhcp_lease.data.address
  role           = var.role
  cluster        = var.cluster
  image          = var.image
  machine_secret = var.machine_secret
  bootstrap      = var.bootstrap
  talos_version  = var.talos_version
  oidc           = var.oidc
  extra_config   = var.extra_config
}
