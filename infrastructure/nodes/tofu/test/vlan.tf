resource "routeros_interface_vlan" "wiecloud_vlan" {
  interface = "ether2"
  name      = "WIECLOUD_VLAN"
  vlan_id   = 1
}

resource "routeros_ip_address" "ip_address" {
  address   = "10.0.0.1/24"
  interface = routeros_interface_vlan.wiecloud_vlan.name
}
