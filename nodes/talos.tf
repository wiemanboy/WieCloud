provider "talos" {}

data "talos_image_factory_extensions_versions" "this" {
  talos_version = "v1.11.5"
  filters = {
    names = [
      "siderolabs/iscsi-tools",
      "siderolabs/util-linux-tools",
    ]
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

output "schematic_id" {
  value = talos_image_factory_schematic.this.id
}