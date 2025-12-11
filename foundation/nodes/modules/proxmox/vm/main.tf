resource "proxmox_vm_qemu" "vm" {
  name        = var.name
  target_node = var.node
  scsihw      = "virtio-scsi-pci"

  cpu {
    cores = var.spec.cpu_cores
  }

  memory = var.spec.memory

  disks {
    ide {
      ide2 {
        cdrom {
          iso = var.iso
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size    = var.spec.disk_size
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id      = 0
    model   = "virtio"
    bridge  = "vmbr0"
    macaddr = var.macaddr
  }
  lifecycle {
    ignore_changes = [
      disks,
      network,
      tags,
      startup_shutdown
    ]
  }
}
