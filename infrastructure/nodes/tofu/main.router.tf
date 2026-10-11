resource "routeros_system_identity" "wiecloud_router" {
  name = "WieCloud_Router"
}
resource "routeros_system_ntp_client" "ntp" {
  enabled = true
  mode    = "unicast"

  servers = [
    "pool.ntp.org",
  ]
}
resource "routeros_system_ntp_server" "ntp" {
  enabled = true
}

resource "routeros_ip_firewall_nat" "vlan_nat" {
  comment       = "wiecloud: allow access to internet"
  chain         = "srcnat"
  out_interface = "ether1"
  action        = "masquerade"
}

module "wireguard" {
  source = "./modules/routeros/port_forward"

  name    = "wireguard"
  address = "10.0.0.150"

  src_port = 51820
  dst_port = 51820
  protocol = "udp"
}
