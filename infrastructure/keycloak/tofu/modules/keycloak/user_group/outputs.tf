output "id" {
  value = keycloak_group.parent_group.id
}

output "child_groups" {
  value = {
    admin = {
      id = keycloak_group.admin_group.id
    }
    user = {
      id = keycloak_group.user_group.id
    }
  }
}
