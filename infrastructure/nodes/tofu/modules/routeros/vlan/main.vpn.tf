resource "routeros_interface_wireguard" "wireguard" {
  comment     = local.resource_tag
  name        = var.vlan_name
  listen_port = 51821
}

resource "routeros_wireguard_peer" "peer" {
  comment         = "${local.resource_tag}: peer"
  name            = "peer"
  interface       = routeros_interface_wireguard.wireguard.name
  public_key      = ""
  allowed_address = ["0.0.0.0/0", ]
}
