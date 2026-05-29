terraform {
  backend "local" {
    path = "/data/state/terraform.tfstate"
  }
}

provider "kubernetes" {}

provider "keycloak" {
  client_id     = "tofudeployer"
  client_secret = var.client_secret
  url           = "https://keycloak.${var.hostname}"
}

provider "random" {}
