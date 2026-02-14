resource "random_password" "s3_default_access_key" {
  length  = 20
  special = false
}

resource "random_password" "s3_default_secret_key" {
  length  = 20
  special = false
}

resource "random_password" "s3_deploy_access_key" {
  length  = 20
  special = false
}

resource "random_password" "s3_deploy_secret_key" {
  length  = 20
  special = false
}

resource "kubernetes_secret_v1" "s3_default_secret" {
  metadata {
    name      = "s3-default-secret"
    namespace = "seaweedfs"
  }
  data = {
    "seaweedfs_s3_config.json" = jsonencode({
      identities = [
        {
          name = "default-s3-user"
          actions = [
            "Read",
            "List",
            "Write"
          ],
          credentials = [
            {
              accessKey = random_password.s3_default_access_key.result
              secretKey = random_password.s3_default_secret_key.result
            }
          ]
        },
        {
          name = "deploy-s3-user"
          actions = [
            "Admin",
          ],
          credentials = [
            {
              accessKey = random_password.s3_deploy_access_key.result
              secretKey = random_password.s3_deploy_secret_key.result
            }
          ]
        },
      ]
    })
  }
}
