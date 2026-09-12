locals {
  resource_tag = var.vlan_name
}

resource "routeros_interface_bridge" "bridge" {
  comment        = local.resource_tag
  name           = var.vlan_name + "-bridge"
  frame_types    = "admit-only-vlan-tagged"
  vlan_filtering = true
}

resource "routeros_interface_bridge_port" "bridge_port" {
  comment     = local.resource_tag
  bridge      = routeros_interface_bridge.bridge.name
  interface   = var.gateway_port
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = var.vlan_id
}

resource "routeros_interface_bridge_vlan" "bridge_vlan" {
  comment  = local.resource_tag
  bridge   = routeros_interface_bridge.bridge.name
  vlan_ids = [var.vlan_id]
  untagged = [routeros_interface_bridge_port.bridge_port.interface]
  tagged   = [routeros_interface_bridge.bridge.name]
}

resource "routeros_interface_vlan" "vlan" {
  comment   = local.resource_tag
  name      = var.vlan_name + "-vlan"
  interface = routeros_interface_bridge.bridge.name
  vlan_id   = var.vlan_id
}

resource "routeros_ip_address" "gateway_ip" {
  comment   = local.resource_tag
  address   = var.subnet
  interface = routeros_interface_vlan.vlan.name
}

resource "routeros_ip_pool" "ip_pool" {
  comment = local.resource_tag
  name    = var.vlan_name + "-ip-pool"
  ranges  = [var.ip_range]
}

resource "routeros_ip_dhcp_server" "dhcp_server" {
  name         = var.vlan_name + "-dhcp"
  address_pool = routeros_ip_pool.ip_pool.name
  interface    = routeros_interface_vlan.vlan.name
}

resource "routeros_interface_list" "vlan" {
  name = upper(var.vlan_name) + "-VLAN"
}

resource "routeros_interface_list_member" "vlan_list_member" {
  comment   = local.resource_tag
  list      = routeros_interface_list.vlan.name
  interface = routeros_interface_vlan.vlan.name
}

resource "routeros_ip_firewall_filter" "rule" {
  comment           = local.resource_tag
  in_interface_list = routeros_interface_list.vlan.name
  place_before      = 0
  action            = "accept"
  chain             = "input"
  // src_address       = "10.0.0.200" // ip of the management pod
}
