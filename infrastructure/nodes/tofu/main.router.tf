resource "routeros_system_identity" "wiecloud_router" {
  name = "WieCloud_Router"
}

resource "routeros_ip_firewall_nat" "vlan_nat" {
  chain         = "srcnat"
  out_interface = "ether1"
  action        = "masquerade"
}
