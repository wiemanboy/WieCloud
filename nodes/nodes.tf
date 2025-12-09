resource "proxmox_storage_iso" "omen-pve-0-metal-amd64-iso" {
  pve_node = "omen-pve-0"
  storage  = "local"
  filename = "metal-amd64.iso"
  url      = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.11.5/metal-amd64.iso"
}

resource "proxmox_vm_qemu" "talos-controlplane-0-test" {
  depends_on  = [proxmox_storage_iso.omen-pve-0-metal-amd64-iso]
  name        = "talos-controlplane-0-test"
  target_node = "omen-pve-0"
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
    macaddr = "BC:24:11:CE:8D:AC"
  }
}

output "ip" {
    value = "${proxmox_vm_qemu.talos-controlplane-0-test.ipconfig0}"
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "this" {
  cluster_name     = "test-cluster"
  machine_type     = "controlplane"
  cluster_endpoint = "https://192.168.178.47:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = "v1.11.5"
}

data "talos_client_configuration" "this" {
  cluster_name         = "test-cluster"
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = ["192.168.178.47"]
}

resource "talos_machine_configuration_apply" "this" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
  node                        = "192.168.178.47"
  config_patches = [
    file("./talos/bare-metal.config.yaml"),
    yamlencode({
      machine = {
        install = {
          image = "factory.talos.dev/installer/${talos_image_factory_schematic.this.id}:v1.11.5"
        }
      }
    })
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.this]
  node                 = "192.168.178.47"
  client_configuration = talos_machine_secrets.this.client_configuration
}
