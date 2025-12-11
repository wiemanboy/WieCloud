terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
    random = {
      source = "hashicorp/random"
      version = "3.7.2"
    }
  }
}
