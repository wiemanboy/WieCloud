module "proxmox_vm" {
  source  = "../proxmox/vm"
  name    = var.name
  node    = var.node
  iso     = var.iso
  macaddr = var.macaddr
}

module "talos_node" {
  source         = "../talos/node"
  endpoint       = var.endpoint
  node           = var.ip
  role           = var.role
  cluster        = var.cluster
  image          = var.image
  machine_secret = var.machine_secret
  bootstrap      = var.bootstrap
}
