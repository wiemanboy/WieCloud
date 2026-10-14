import regex

schema StoreRef:
  kind: str
  name: str

compose: (any) -> [{str:any}] = lambda params: any {
  ctx = params.ctx
  backups: any = ctx["apiextensions.crossplane.io/environment"]["backups"]

  observed_xr: any = params.oxr

  # Repo secret
  _desired_repo_secret = [create_external_secret(
    backup.repo.secret.name,
    observed_xr.metadata.name,
    {
      kind = backup.repo.secret.storeRef.kind
      name = backup.repo.secret.storeRef.name
    }
    [backup.repo.secret.password]) for backup in backups]

  # S3 credentials secret
  _desired_s3_credentials_secret = create_external_secret(
    "",
    observed_xr.metadata.name,
    {
      kind = ""
      name = ""
    },
    [])

  # Schedules
  _desired_schedules = [
    create_schedule(observed_xr.metadata.name, backup.name) for backup in backups
  ]

  # Restores
  restores = observed_xr.spec.restores
  _desired_restores = [
    create_restore(restore.name, observed_xr.metadata.name) for restore in restores for backup in backups
  ]

  # Update status
  _desired_xr: {str:any} = {
    **params.dxr
  }

  items: [{str:any}] = [_desired_xr, *_desired_repo_secret, _desired_s3_credentials_secret, *_desired_schedules, *_desired_restores]
}

create_external_secret = lambda name: str, xr_name: str, storeRef: StoreRef, secrets: [any] {
  {
    apiVersion = "external-secrets.io/v1"
    kind = "ExternalSecret"
    metadata = metadata(regex.replace(name, "/", "-"), xr_name, "externalsecret" )
    spec = {
      secretStoreRef = {
        kind = storeRef.kind
        name = storeRef.name
      }

      target = {
        name = name
      }

      data = [
        {
          secretKey = secret
          remoteRef = {
            key = name
            property = secret
          }
        } for secret in secrets
      ]
    }
  }
}

create_schedule = lambda xr_name: str, backup_name {
  {
    apiVersion = "k8up.io/v1"
    kind = "Schedule"
    metadata = metadata(backup_name, xr_name, "schedule")
    spec = {
      backend = {
        repoPasswordSecretRef = {
          name = ""
          key = ""
        }
        s3 = {
          endpoint = ""
          bucket = ""
          accessKeyIDSecretRef = {
            name = ""
            key = ""
          }
          secretAccessKeySecretRef = {
            name = ""
            key = ""
          }
        }
      }

      backup = {
        schedule = ""
        failedJobsHistoryLimit = 2
        successfulJobHistoryLimit = 1
        podSecurityContext = {
          runAsUser = 0
          fsGroup = 999
          fsGroupChangePolicy = "OnRootMismatch"
        }
      }

      check = {
        schedule = ""
        failedJobsHistoryLimit = 2
        successfulJobHistoryLimit = 0
      }

      prune = {
        schedule = ""
        failedJobsHistoryLimit = 2
        successfulJobHistoryLimit = 0
        retention = {
          keepLast = 0
          keepDaily = 0
        }
      }
    }
  }
}

create_restore = lambda name: str, xr_name: str {
  {
    apiVersion = "k8up.io/v1"
    kind = "Restore"
    metadata = metadata(name, xr_name, "restore")
    spec = {
      restoreMethod = {
        folder = {
          claimName = ""
        }
      }

      snapshot = ""

      backend = {
        repoPasswordSecretRef = {
          name = ""
          key = ""
        }
        s3 = {
          endpoint = ""
          bucket = ""
          accessKeyIDSecretRef = {
            name = ""
            key = ""
          }
          secretAccessKeySecretRef = {
            name = ""
            key = ""
          }
        }
      }

      podSecurityContext = {
        fsGroup = 65532
        fsGroupChangePolicy = "OnRootMismatch"
      }
    }
  }
}

metadata: (str, str, str) -> {str:any} = lambda name: str, xr_name: str, resource_name: str {
  {
    name = name
    annotations = {
      "krm.kcl.dev/composition-resource-name" = resource_name
    }
    labels = {"wieman.cloud/backup" = xr_name}
  }
}
