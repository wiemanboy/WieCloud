resource "keycloak_realm" "wiecloud" {
  realm        = "wiecloud"
  enabled      = true
  display_name = "WieCloud"
}
