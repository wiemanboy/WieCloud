resource "routeros_interface_wireguard" "wireguard" {
  comment     = local.resource_tag
  name        = var.vlan_name
  listen_port = 51822
}

resource "routeros_wireguard_keys" "peer" {
  number = 1
}

resource "routeros_wireguard_peer" "peer" {
  comment         = "${local.resource_tag}: peer"
  name            = "peer"
  interface       = routeros_interface_wireguard.wireguard.name
  private_key     = routeros_wireguard_keys.peer.keys[0].private
  public_key      = routeros_wireguard_keys.peer.keys[0].public
  allowed_address = ["0.0.0.0/0", "::/0"]
  # client_dns         = local.gateway
  client_address     = "10.20.0.1/24"
  client_endpoint    = "wireguard.wieman.cloud"
  client_listen_port = 51822
}

resource "routeros_ip_address" "wireguard" {
  comment   = local.resource_tag
  address   = routeros_wireguard_peer.peer.client_address
  interface = routeros_interface_wireguard.wireguard.name
}

resource "routeros_ip_firewall_filter" "wireguard_in" {
  comment      = "${local.resource_tag}: allow wireguard"
  chain        = "input"
  action       = "accept"
  protocol     = "udp"
  dst_port     = 51822
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
