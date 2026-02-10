resource "keycloak_realm" "infrastructure" {
  realm        = "infrastructure-test"
  enabled      = true
  display_name = "Infrastructure-test"
}
