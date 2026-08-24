# resource "routeros_interface_bridge" "wiecloud_bridge" {
#   name           = "wiecloud-bridge"
#   vlan_filtering = true
# }

# resource "routeros_interface_bridge_port" "wiecloud_bridge_port" {
#   bridge    = routeros_interface_bridge.wiecloud_bridge.name
#   interface = "ether2"
#   pvid      = "10"
# }

# resource "routeros_interface_bridge_vlan" "wiecloud_bridge_vlan" {
#   bridge   = routeros_interface_bridge.wiecloud_bridge.name
#   vlan_ids = [10]

#   tagged   = [routeros_interface_bridge.wiecloud_bridge.name]
#   untagged = ["ether2"]
# }

# resource "routeros_interface_vlan" "wiecloud_vlan" {
#   interface = routeros_interface_bridge.wiecloud_bridge.name
#   name      = "wiecloud-vlan"
#   vlan_id   = 10
# }

# resource "routeros_ip_address" "ip_address" {
#   address   = "10.0.0.1/24"
#   interface = routeros_interface_vlan.wiecloud_vlan.name
# }
