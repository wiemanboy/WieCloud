module "proxmox_vm" {
  source = "../proxmox/vm"
  name   = var.name
  node   = var.host
  iso    = var.iso
  disk   = var.disk
  spec   = var.spec
}

resource "time_sleep" "wait_for_vm_boot" {
  depends_on      = [module.proxmox_vm]
  create_duration = "30s"
}

module "dhcp_lease" {
  source     = "../routeros/find_dhcp_lease"
  depends_on = [time_sleep.wait_for_vm_boot]

  mac_address = module.proxmox_vm.macaddr
}

module "talos_node" {
  source     = "../talos/node"
  depends_on = [module.dhcp_lease]

  name           = var.name
  zone           = var.host
  region         = var.rack
  endpoint       = var.endpoint != null ? var.endpoint : module.dhcp_lease.data.address
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
