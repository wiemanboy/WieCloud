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

module "http" {
  source = "./modules/routeros/port_forward"

  name    = "http"
  address = "10.0.0.151"

  src_port = 80
  dst_port = 80
  protocol = "tcp"
}

module "https" {
  source = "./modules/routeros/port_forward"

  name    = "https"
  address = "10.0.0.151"

  src_port = 443
  dst_port = 443
  protocol = "tcp"
}

module "minecraft" {
  source = "./modules/routeros/port_forward"

  name    = "minecraft"
  address = "10.0.0.151"

  src_port = 25565
  dst_port = 25565
  protocol = "tcp"
}


module "minecraft-voicechat" {
  source = "./modules/routeros/port_forward"

  name    = "minecraft-voicechat"
  address = "10.0.0.151"

  src_port = 24454
  dst_port = 24454
  protocol = "udp"
}

module "satisfactory-tcp" {
  source = "./modules/routeros/port_forward"

  name    = "satisfactory"
  address = "10.0.0.151"

  src_port = 7777
  dst_port = 7777
  protocol = "tcp"
}

module "satisfactory-udp" {
  source = "./modules/routeros/port_forward"

  name    = "satisfactory"
  address = "10.0.0.151"

  src_port = 7777
  dst_port = 7777
  protocol = "udp"
}

module "satisfactory-messaging" {
  source = "./modules/routeros/port_forward"

  name    = "satisfactory-messaging"
  address = "10.0.0.151"

  src_port = 8888
  dst_port = 8888
  protocol = "tcp"
}
