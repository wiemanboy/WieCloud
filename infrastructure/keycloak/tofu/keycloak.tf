resource "keycloak_realm" "wiecloud" {
  realm        = "wiecloud"
  enabled      = true
  display_name = "WieCloud"

  sso_session_idle_timeout = "12h"
  sso_session_max_lifespan = "24h"
}
