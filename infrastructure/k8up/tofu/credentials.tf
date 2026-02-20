resource "random_password" "s3_access_key" {
  length  = 50
  special = false
}

resource "random_password" "s3_secret_key" {
  length  = 50
  special = false
}

resource "random_password" "s3_deploy_access_key" {
  length  = 50
  special = false
}

resource "random_password" "s3_deploy_secret_key" {
  length  = 50
  special = false
}

resource "kubernetes_secret_v1" "s3_secret" {
  metadata {
    name      = local.values.backend.s3.secret.name
    namespace = "k8up"
  }
  data = {
    "seaweedfs_s3_config.json" = jsonencode({
      identities = [
        {
          name = "k8up-s3-user"
          actions = [
            "Read",
            "List",
            "Write"
          ],
          credentials = [
            {
              accessKey = random_password.s3_access_key.result
              secretKey = random_password.s3_secret_key.result
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
    }),
    access_key = random_password.s3_access_key.result
    secret_key = random_password.s3_secret_key.result
  }
}

resource "random_password" "encryption_password" {
  length  = 50
  special = false
}

resource "kubernetes_secret_v1" "encryption_secret" {
  metadata {
    name      = local.values.backend.repoPasswordSecretRef.name
    namespace = "k8up"
  }
  data = {
    password = random_password.encryption_password.result
  }
}
