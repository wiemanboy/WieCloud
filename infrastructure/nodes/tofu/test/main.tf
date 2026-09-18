provider "routeros" {
  hosturl  = "http://10.0.0.1"
  username = "admin"
  password = var.routeros_password
}

resource "routeros_system_identity" "wiecloud_router" {
  name = "WieCloud_Router"
}

data "routeros_ip_dhcp_server_leases" "leases" {}

output "dhcp_leases" {
  value = data.routeros_ip_dhcp_server_leases.leases.data[1].host_name
}
