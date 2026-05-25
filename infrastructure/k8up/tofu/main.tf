terraform {
  backend "local" {
    path = "/data/state/terraform.tfstate"
  }
}

provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
