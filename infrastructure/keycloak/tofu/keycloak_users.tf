resource "random_password" "jarno_wieman_password" {
  length = 20
}

resource "keycloak_user" "jarno_wieman" {
  realm_id       = keycloak_realm.infrastructure.id
  username       = "jarno_wieman"
  first_name     = "Jarno"
  last_name      = "Wieman"
  email          = "wiemanboy@gmail.com"
  email_verified = true
  enabled        = true

  initial_password {
    value     = random_password.jarno_wieman_password.result
    temporary = true
  }

  required_actions = [
    "UPDATE_PASSWORD",
    "CONFIGURE_TOTP",
  ]

  lifecycle {
    ignore_changes = [
      required_actions
    ]
  }
}

resource "keycloak_group_memberships" "infra_admin_members" {
  realm_id = keycloak_realm.infrastructure.id
  group_id = keycloak_group.infra_admin.id
  members  = [keycloak_user.jarno_wieman.username]
}

resource "keycloak_group_memberships" "infra_harbor_admin_members" {
  realm_id = keycloak_realm.infrastructure.id
  group_id = keycloak_group.infra_harbor_admin.id
  members  = [keycloak_user.jarno_wieman.username]
}

resource "keycloak_group_memberships" "infra_keycloak_admin_members" {
  realm_id = keycloak_realm.infrastructure.id
  group_id = keycloak_group.infra_keycloak_admin.id
  members  = [keycloak_user.jarno_wieman.username]
}

resource "keycloak_group_memberships" "app_admin_members" {
  realm_id = keycloak_realm.infrastructure.id
  group_id = keycloak_group.app_admin.id
  members  = [keycloak_user.jarno_wieman.username]
}

resource "keycloak_group_memberships" "app_nextcloud_members" {
  realm_id = keycloak_realm.infrastructure.id
  group_id = keycloak_group.app_nextcloud.id
  members  = [keycloak_user.jarno_wieman.username]
}
