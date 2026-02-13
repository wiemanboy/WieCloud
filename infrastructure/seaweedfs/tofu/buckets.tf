resource "aws_s3_bucket" "default_s3_bucket" {
  depends_on = [kubernetes_secret_v1.s3_default_secret]
  bucket     = "s3-bucket"
}
