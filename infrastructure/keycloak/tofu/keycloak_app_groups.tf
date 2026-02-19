module "app_group" {
  source   = "./modules/keycloak/user_group"
  realm_id = keycloak_realm.infrastructure.id
  name     = "app"
}

module "app_nextcloud_group" {
  source    = "./modules/keycloak/user_group"
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = module.app_group.id
  name      = "nextcloud"
}
