resource "routeros_interface_wireguard" "wireguard" {
  comment     = local.resource_tag
  name        = var.vlan_name
  listen_port = 51822
}

resource "routeros_wireguard_keys" "peer" {
  number = 1
}

resource "routeros_wireguard_peer" "peer" {
  comment            = "${local.resource_tag}: peer"
  name               = "peer"
  interface          = routeros_interface_wireguard.wireguard.name
  public_key         = routeros_wireguard_keys.peer.keys[0].public
  allowed_address    = ["0.0.0.0/0", "::/0"]
  # client_dns         = local.gateway
  client_endpoint    = "wireguard.wieman.cloud"
  client_listen_port = 51822
}

resource "routeros_ip_address" "wireguard" {
  comment   = local.resource_tag
  address   = "10.20.0.1/24"
  interface = routeros_interface_wireguard.wireguard.name
}

resource "routeros_ip_firewall_filter" "wireguard_in" {
  comment           = "${local.resource_tag}: allow wireguard"
  chain             = "input"
  action            = "accept"
  protocol          = "udp"
  dst_port          = 51822
  in_interface_list = "WAN" # whatever your WAN list is called
  place_before      = 2
}

resource "routeros_ip_firewall_filter" "wireguard_to_vlan" {
  comment            = "${local.resource_tag}: wireguard -> vlan"
  chain              = "forward"
  action             = "accept"
  in_interface       = routeros_interface_wireguard.wireguard.name
  out_interface_list = routeros_interface_list.vlan.name
  place_before       = 3 # must sit above any "drop all forward" / inter-VLAN drop rule
}
