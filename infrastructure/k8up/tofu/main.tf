terraform {
  backend "kubernetes" {
    secret_suffix     = "state"
    in_cluster_config = true
    namespace         = var.namespace
  }
}

provider "aws" {
  region = "eu-central-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
