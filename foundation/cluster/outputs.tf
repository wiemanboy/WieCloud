output "basic_auth" {
  sensitive = true
  value = {
    username = local.username
    password = random_password.basic_auth_password.result
  }
}
