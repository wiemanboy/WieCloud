resource "routeros_interface_bridge" "wiecloud_bridge" {
  comment        = "wiecloud"
  name           = "wiecloud-bridge"
  frame_types    = "admit-only-vlan-tagged"
  vlan_filtering = true
}

resource "routeros_interface_bridge_port" "wiecloud_bridge_ether2" {
  comment     = "wiecloud"
  bridge      = routeros_interface_bridge.wiecloud_bridge.name
  interface   = "ether2"
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = 10
}

resource "routeros_interface_bridge_vlan" "wiecloud_bridge_vlan" {
  comment  = "wiecloud"
  bridge   = routeros_interface_bridge.wiecloud_bridge.name
  vlan_ids = ["10"]
  untagged = [routeros_interface_bridge_port.wiecloud_bridge_ether2.interface]
  tagged   = [routeros_interface_bridge.wiecloud_bridge.name]
}

resource "routeros_interface_vlan" "wiecloud_vlan" {
  comment   = "wiecloud"
  name      = "wiecloud-vlan"
  interface = routeros_interface_bridge.wiecloud_bridge.name
  vlan_id   = 10
}

resource "routeros_ip_address" "wiecloud_gateway_ip" {
  comment   = "wiecloud"
  address   = "10.0.0.1/24"
  interface = routeros_interface_vlan.wiecloud_vlan.name
}

resource "routeros_ip_pool" "wiecloud_ip_pool" {
  comment = "wiecloud"
  name    = "wiecloud-ip-pool"
  ranges  = ["10.0.0.100-10.0.0.200"]
}

resource "routeros_ip_dhcp_server" "wiecloud_dhcp_server" {
  name         = "wiecloud_dhcp"
  address_pool = routeros_ip_pool.wiecloud_ip_pool.name
  interface    = routeros_interface_vlan.wiecloud_vlan.name
}

resource "routeros_interface_list" "vlan" {
  name    = "VLAN"
}

resource "routeros_interface_list_member" "list_member" {
  comment   = "wiecloud"
  list      = routeros_interface_list.vlan.name
  interface = routeros_interface_vlan.wiecloud_vlan.name
}

resource "routeros_ip_firewall_filter" "rule" {
  comment           = "wiecloud: Allow all coming from VLAN"
  in_interface_list = routeros_interface_list.vlan.name
  place_before      = 0
  action            = "accept"
  chain             = "input"
  // src_address       = "10.0.0.200" // ip of the management pod
}
