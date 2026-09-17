terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.2.1"
    }
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.9.0"
    }
  }
}
