provider "aws" {
  access_key = random_password.s3_deploy_access_key.result
  secret_key = random_password.s3_deploy_secret_key.result

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true

  s3_use_path_style = true
  endpoints {
    s3 = "https://default.s3.wieman.cloud"
  }
}

provider "kubernetes" {
  config_path = "../../../foundation/config/kubeconfig"
}

provider "random" {}
