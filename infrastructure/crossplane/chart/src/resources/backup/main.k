import regex

schema SecretRef:
  name: str
  key: str

schema S3SecretRef:
  accessKey: SecretRef
  secretKey: SecretRef

schema StoreRef:
  kind: str
  name: str

schema Secret:
  name: str
  storeRef: StoreRef

schema S3Secret(Secret):
  accessKey: str
  secretKey: str

schema RepoSecret(Secret):
  password: str
  key?: str # Temp

schema S3:
  endpoint: str
  secret: S3Secret

schema Repo:
  secret: RepoSecret

schema Schedule:
  backup: str
  prune: str
  "check": str

schema Retention:
  keepLast: int
  keepDaily: int

schema Backup:
  name: str
  s3: S3
  repo: Repo
  schedule: Schedule
  retention: Retention
  default?: any # Temp

schema SecurityContext:
  runAsUser?: int
  fsGroup?: int
  fsGroupChangePolicy?: str

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
    create_schedule(
      observed_xr.metadata.name,
      observed_xr.spec.target.bucket,
      {
        name = dash_name(backup.repo.secret.name)
        key: backup.repo.secret.password
      },
      {
        accessKey = {
          name = dash_name(backup.s3.secret.name)
          key = backup.s3.secret.accessKey
        }
        secretKey = {
          name = dash_name(backup.s3.secret.name)
          key = backup.s3.secret.secretKey
        }
      },
      observed_xr.spec.backup.podSpec.securityContext,
      backup
    ) for backup in backups
  ]

  # Restores
  restores = observed_xr.spec.restores
  _desired_restores = [
    create_restore(
      restore.name,
      observed_xr.metadata.name,
      restore.claim.name,
      restore.snapshot,
      get_resource_by_name(_desired_schedules, restore.fromBackup).spec.backend or {}
      ) for restore in restores if restore.enabled == True
  ]

  if observed_xr.spec.enabled == False:
    _desired_schedules = []

  # Set ready
  _desired_external_secrets = [*_desired_repo_secret, *_desired_s3_credentials_secret]
  observed_external_secrets = get_observed_resources_by_resource_type(params, "externalsecret")
  [ set_ready(get_resource_by_name(_desired_external_secrets, secret.metadata.name )) for secret in observed_external_secrets if any_true([
      condition.type == "Ready" and condition.status == "True"
      for condition in secret.status?.conditions or []
  ]) ]

  observed_schedules = get_observed_resources_by_resource_type(params, "schedule")
  [ set_ready(get_resource_by_name(_desired_schedules, schedule.metadata.name )) for schedule in observed_schedules if any_true([
      condition.type == "Ready" and condition.status == "True"
      for condition in schedule.status?.conditions or []
  ]) ]

  observed_restores = get_observed_resources_by_resource_type(params, "restore")
  [ set_ready(get_resource_by_name(_desired_restores, restore.metadata.name )) for restore in observed_restores if any_true([
      condition.type == "Ready" and condition.status == "True"
      for condition in restore.status?.conditions or []
  ]) ]

  # Update status
  _desired_xr: {str:any} = {
    **params.dxr
    status.targets = [
      {
        name = backup.name
        endpoint = backup.s3.endpoint
        schedule = backup.schedule
        retention = backup.retention
      } for backup in backups
    ]
  }

  items: [{str:any}] = [_desired_xr, *_desired_external_secrets, *_desired_schedules, *_desired_restores]
}

create_external_secret = lambda name: str, xr_name: str, store_ref: StoreRef, secrets: [any] {
  dashed_name = dash_name(name)

  {
    apiVersion = "external-secrets.io/v1"
    kind = "ExternalSecret"
    metadata = metadata(dashed_name, xr_name, "externalsecret.${dashed_name}" )
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

create_schedule: (str, str, SecretRef, S3SecretRef, SecurityContext, Backup) -> {str:any} = lambda xr_name: str, bucket: str, repo_secret_ref: SecretRef, s3_secret_ref: S3SecretRef, backup_pod_security_context: SecurityContext, _backup: Backup {
  {
    apiVersion = "k8up.io/v1"
    kind = "Schedule"
    metadata = metadata(_backup.name, xr_name, "schedule.${_backup.name}")
    spec = {
      backend = {
        repoPasswordSecretRef = repo_secret_ref
        s3 = {
          endpoint = _backup.s3.endpoint
          bucket = bucket
          accessKeyIDSecretRef = s3_secret_ref.accessKey
          secretAccessKeySecretRef = s3_secret_ref.secretKey
        }
      }

      backup = {
        schedule = _backup.schedule.backup
        failedJobsHistoryLimit = 2
        successfulJobsHistoryLimit = 1
        podSecurityContext = SecurityContext {
            runAsUser = backup_pod_security_context.runAsUser or 0
            fsGroup = backup_pod_security_context.fsGroup or 999
            fsGroupChangePolicy = backup_pod_security_context.fsGroupChangePolicy or "OnRootMismatch"
        }
      }

      check = {
        schedule = _backup.schedule.backup
        failedJobsHistoryLimit = 2
        successfulJobsHistoryLimit = 0
      }

      prune = {
        schedule = _backup.schedule.prune
        failedJobsHistoryLimit = 2
        successfulJobsHistoryLimit = 0
        retention = _backup.retention
      }
    }
  }
}

create_restore = lambda name: str, xr_name: str, claim_name: str, snapshot: str, backend: {str:any} {
  {
    apiVersion = "k8up.io/v1"
    kind = "Restore"
    metadata = metadata(name, xr_name, "restore.${name}")
    spec = {
      restoreMethod = {
        folder = {
          claimName = claim_name
        }
      }

      snapshot = snapshot

      backend = backend

      podSecurityContext = {
        fsGroup = 65532
        fsGroupChangePolicy = "OnRootMismatch"
      }
    }
  }
}

dash_name: (str) -> str = lambda name: str {
  dashed_name = regex.replace(name, "/", "-")
}

get_observed_resources_by_resource_type = lambda params: any, resource_type: str {
  ocds = params.ocds

  [params.ocds[name]?.Resource for name in params.ocds if name.startswith(resource_type)]
}

get_resource_by_name = lambda resources: [], name: str {
  [ resource for resource in resources if resource.metadata.name == name][0] or None
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
