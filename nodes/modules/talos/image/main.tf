data "talos_image_factory_extensions_versions" "talos_extensions" {
  talos_version = "v1.11.5"
  filters = {
    names = [
      "siderolabs/iscsi-tools",
      "siderolabs/util-linux-tools",
    ]
  }
}

resource "talos_image_factory_schematic" "talos_image" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.talos_extensions.extensions_info.*.name
        }
      }
    }
  )
}