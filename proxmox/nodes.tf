resource "proxmox_storage_iso" "gigabyte-pve-0-metal-amd64-iso" {
  pve_node = "gigabyte-pve-0"
  storage  = "local"
  filename = "metal-amd64.iso"
  url      = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.11.5/metal-amd64.iso"
}

resource "proxmox_vm_qemu" "talos-controlplane-0" {
  name        = "talos-controlplane-0"
  target_node = "gigabyte-pve-0"
  scsihw      = "virtio-scsi-pci"

  cpu {
    cores = 4
  }

  memory = 4096

  disks {
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/metal-amd64.iso"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size    = 100
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
    macaddr = "BC:24:11:F5:47:41"
  }
}

resource "proxmox_vm_qemu" "talos-wroker-0" {
  name        = "talos-worker-0"
  target_node = "gigabyte-pve-0"
  scsihw      = "virtio-scsi-pci"

  cpu {
    cores = 8
  }

  memory = 8192

  disks {
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/metal-amd64.iso"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size    = 200
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
    macaddr = "BC:24:11:26:37:90"
  }
}
