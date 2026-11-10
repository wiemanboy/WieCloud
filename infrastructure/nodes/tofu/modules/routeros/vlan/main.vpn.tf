locals {
  peers = flatten([
    for user in var.vpn.var.vpn.users : [
      for peer in user.peers : "${user.name}_${peer}"
    ]
  ])
}

resource "routeros_interface_wireguard" "wireguard" {
  comment     = "${local.resource_tag}: VPN"
  name        = "${var.vlan_name}-vpn"
  listen_port = var.vpn.port
}

resource "routeros_wireguard_keys" "peers" {
  number = length(local.peers)
}

resource "routeros_wireguard_peer" "peer" {
  for_each = toset(local.peers)

  comment            = "${local.resource_tag}: peer ${each.value}"
  name               = each.value
  interface          = routeros_interface_wireguard.wireguard.name
  private_key        = routeros_wireguard_keys.peers.keys[count.index].private
  public_key         = routeros_wireguard_keys.peers.keys[count.index].public
  allowed_address    = ["0.0.0.0/0", "::/0"]
  client_address     = "${cidrhost("${var.vpn.address}/24", count.index + 2)}/32"
  client_endpoint    = var.vpn.endpoint
  client_listen_port = var.vpn.port
}

resource "routeros_ip_address" "wireguard" {
  comment   = local.resource_tag
  address   = "${var.vpn.address}/24"
  interface = routeros_interface_wireguard.wireguard.name
}

resource "routeros_ip_firewall_filter" "wireguard_in" {
  comment      = "${local.resource_tag}: allow wireguard access"
  chain        = "input"
  action       = "accept"
  protocol     = "udp"
  dst_port     = var.vpn.port
  place_before = 2
}

resource "routeros_ip_firewall_filter" "wireguard_vlan_access" {
  comment            = "${local.resource_tag}: allow wireguard to VLAN"
  chain              = "forward"
  action             = "accept"
  in_interface       = routeros_interface_wireguard.wireguard.name
  out_interface_list = routeros_interface_list.vlan.name
  place_before       = 3
}
