resource "keycloak_realm" "infrastructure" {
  realm        = "infrastructure"
  enabled      = true
  display_name = "WieCloud"
}
