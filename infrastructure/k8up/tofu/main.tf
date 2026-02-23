provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true

  s3_use_path_style = true
  endpoints {
    s3 = "https://k8up.s3.wieman.cloud"
  }
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "backup-bucket"
}
