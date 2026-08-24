provider "routeros" {
  hosturl  = "http://192.168.88.1"
  username = "admin"
  password = var.routeros_password
}

resource "routeros_system_identity" "identity" {
  name = "WieCloudRouter"
}
