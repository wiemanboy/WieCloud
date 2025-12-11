# Provisioning

## Aquire ip

1. Manually create VM in Proxmox
2. Wait for a mac address and ip to be assigned
3. Shut down and delete the VM

## Tofu

Add a node:

```tf
module "<node_name>" {
  source   = local.node_module_source
  name     = "<node_name>"
  node     = "<proxmox_node_name>"
  endpoint = "<control_plane_ip>"
  cluster  = local.cluster
  role     = "<worker | controlplane>"

  ip      = "<ip>"
  macaddr = "<mac_address>"

  talos_version = local.talos_version
  iso           = local.iso
  image         = local.image
}
```

`tofu apply`

If bootstrapping fails `tofu destroy -target=module.<node_name>` and try again
