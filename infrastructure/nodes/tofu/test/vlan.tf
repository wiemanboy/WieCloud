resource "routeros_interface_bridge" "bridge1" {
  name           = "bridge1"
  frame_types    = "admit-only-vlan-tagged"
  vlan_filtering = true
}

resource "routeros_interface_bridge_port" "bridge1_ether2" {
  bridge      = "bridge1"
  interface   = "ether2"
  frame_types = "admit-only-vlan-tagged"
}

resource "routeros_interface_bridge_port" "bridge1_ether3" {
  bridge      = "bridge1"
  interface   = "ether3"
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = 30
}

resource "routeros_interface_bridge_port" "bridge1_ether4" {
  bridge      = "bridge1"
  interface   = "ether4"
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = 40
}

resource "routeros_bridge_vlan" "vlan_30" {
  bridge   = "bridge1"
  tagged   = ["ether2"]
  vlan_ids = [30]
}

resource "routeros_bridge_vlan" "vlan_40" {
  bridge   = "bridge1"
  tagged   = ["ether2"]
  vlan_ids = [40]
}

resource "routeros_bridge_vlan" "vlan_99" {
  bridge   = "bridge1"
  tagged   = ["ether2", "bridge1"]
  vlan_ids = [99]
}

resource "routeros_interface_vlan" "vlan_99" {
  name      = "MGMT"
  interface = "bridge1"
  vlan_id   = 99

}

resource "routeros_ip_address" "ip_address" {
  address   = "192.168.99.1/24"
  interface = "MGMT"
}

resource "routeros_interface_vlan" "vlan30" {
  name      = "VLAN30"
  interface = "bridge1"
  vlan_id   = 30
}

resource "routeros_ip_address" "vlan30" {
  address   = "192.168.30.1/24"
  interface = "VLAN30"
}
