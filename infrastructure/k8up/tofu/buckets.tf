resource "aws_s3_bucket" "s3_bucket" {
  depends_on = [kubernetes_secret_v1.s3_secret]
  bucket     = local.values.backend.s3.bucket
}
