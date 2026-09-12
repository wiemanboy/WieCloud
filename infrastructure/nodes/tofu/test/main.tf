provider "routeros" {
  hosturl  = "http://10.0.0.1"
  username = "admin"
  password = var.routeros_password
}

resource "routeros_system_identity" "wiecloud_router" {
  name = "WieCloud_Router"
}
