# resource "routeros_ip_firewall_nat" "http" {
#   comment  = "HTTP"
#   chain    = "dstnat"
#   action   = "dst-nat"
#   protocol = "tcp"
#   src_port = 8080
#   dst_port = 80
#   to_ports = 80
# }

# resource "routeros_ip_firewall_nat" "https" {
#   comment  = "HTTPS"
#   chain    = "dstnat"
#   action   = "dst-nat"
#   protocol = "tcp"
#   src_port = 8443
#   dst_port = 443
# }

