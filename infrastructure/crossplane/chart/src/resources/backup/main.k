import regex

schema StoreRef:
  kind: str
  name: str

compose: (any) -> [{str:any}] = lambda params: any {
  ctx = params.ctx
  backups: any = ctx["apiextensions.crossplane.io/environment"]["backups"]

  observed_xr: any = params.oxr

  # Repo secrets
  _desired_repo_secret = [create_external_secret(
    backup.repo.secret.name,
    observed_xr.metadata.name,
    {
      kind = backup.repo.secret.storeRef.kind
      name = backup.repo.secret.storeRef.name
    }
    [backup.repo.secret.password]) for backup in backups]

  # S3 credentials secrets
  _desired_s3_credentials_secret = [create_external_secret(
    backup.s3.secret.name,
    observed_xr.metadata.name,
    {
      kind = backup.s3.secret.storeRef.kind
      name = backup.s3.secret.storeRef.name
    },
    [
      backup.s3.secret.accessKey,
      backup.s3.secret.secretKey
    ]) for backup in backups]

  # Schedules
  _desired_schedules = [
    create_schedule(observed_xr.metadata.name, backup.name) for backup in backups
  ]

  # Restores
  restores = observed_xr.spec.restores
  _desired_restores = [
    create_restore(restore.name, observed_xr.metadata.name) for restore in restores for backup in backups
  ]

  # Set ready
  _desired_external_secrets = [*_desired_repo_secret, *_desired_s3_credentials_secret]
  observed_external_secrets = get_observed_resources_by_resource_type(params, "externalsecret")
  _external_secrets_readiness = {
    name: any_true([
        c.type == "Ready" and c.status == "True"
        for c in observed_external_secrets[name]?.Resource?.status?.conditions or []
    ])
    for name in _desired_external_secrets
  }

  observed_schedules = get_observed_resources_by_resource_type(params, "schedule")
  _schedules_readiness = {
      name: any_true([
          c.type == "Ready" and c.status == "True"
          for c in observed_schedules[name]?.Resource?.status?.conditions or []
      ])
      for name in observed_schedules
  }

  observed_restores = get_observed_resources_by_resource_type(params, "restore")
  _restores_readiness = {
      name: any_true([
          c.type == "Ready" and c.status == "True"
          for c in observed_restores[name]?.Resource?.status?.conditions or []
      ])
      for name in observed_restores
  }

  # Update status
  _desired_xr: {str:any} = {
    **params.dxr
  }

  items: [{str:any}] = [_desired_xr, *_desired_external_secrets, *_desired_schedules, *_desired_restores]
}

create_external_secret = lambda name: str, xr_name: str, store_ref: StoreRef, secrets: [any] {
  stripped_name = regex.replace(name, "/", "-")

  {
    apiVersion = "external-secrets.io/v1"
    kind = "ExternalSecret"
    metadata = metadata(stripped_name, xr_name, "externalsecret.${stripped_name}" )
    spec = {
      secretStoreRef = {
        kind = store_ref.kind
        name = store_ref.name
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
    metadata = metadata(backup_name, xr_name, "schedule.${backup_name}")
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
    metadata = metadata(name, xr_name, "restore.${name}")
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

get_observed_resources_by_resource_type = lambda params: any, resource_type: str {
  ocds = params.ocds

  resources = {
    name: params.ocds[name]?.Resource
    for name in params.ocds
    if name.startswith(resource_type)
  }
}

set_ready = lambda resource: any {
  resource.metadata.annotations["krm.kcl.dev/ready"] = "True"
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
