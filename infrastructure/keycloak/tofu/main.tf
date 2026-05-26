# terraform {
#   backend "local" {
#     path = "/data/state/terraform.tfstate"
#   }
# }

provider "kubernetes" {}

provider "keycloak" {
  client_id = "admin-cli"
  username  = var.keycloak_admin_username
  password  = var.keycloak_admin_password
  url       = "https://keycloak.${var.hostname}"
}

provider "random" {}
