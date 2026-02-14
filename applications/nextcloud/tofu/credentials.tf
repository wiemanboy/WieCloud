resource "random_password" "s3_access_key" {
  length  = 50
  special = false
}

resource "random_password" "s3_secret_key" {
  length  = 50
  special = false
}

resource "kubernetes_secret_v1" "s3_default_secret" {
  metadata {
    name      = "s3-secret"
    namespace = "nextcloud"
  }
  data = {
    "seaweedfs_s3_config.json" = jsonencode({
      identities = [
        {
          name = "s3-user"
          actions = [
            "Admin",
          ],
          credentials = [
            {
              accessKey = random_password.s3_access_key.result
              secretKey = random_password.s3_secret_key.result
            }
          ]
        },
      ]
    }),
    access_key = random_password.s3_access_key.result
    secret_key = random_password.s3_secret_key.result
  }
}
