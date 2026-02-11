output "users" {
  sensitive = true
  value = [
    {
      username         = keycloak_user.jarno_wieman.username,
      initial_password = keycloak_user.jarno_wieman.initial_password[0].value
    }
  ]
}
