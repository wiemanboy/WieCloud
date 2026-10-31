resource "routeros_ip_firewall_nat" "port_forward" {
  comment           = "wiecloud: ${var.name}"
  chain             = "dstnat"
  protocol          = var.protocol
  dst_port          = var.src_port
  in_interface_list = "WAN"
  action            = "dst-nat"
  to_addresses      = "10.0.0.150"
  to_ports          = var.dst_port
}
