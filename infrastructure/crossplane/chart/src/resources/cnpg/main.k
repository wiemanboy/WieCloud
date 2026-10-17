schema StoreRef:
  kind: str
  name: str

schema Resources:
  limits?: Resource
  requests?: Resource

schema Resource:
  cpu?: str
  memory?: str

schema S3Credentials:
  secret: str
  accessKey: str
  secretKey: str

compose = lambda params: any {
  ctx: any = params.ctx
  cnpg: any = ctx["apiextensions.crossplane.io/environment"]["cnpg"]

  observed_xr: any = params.oxr

  # S3 credentials secret
  _desired_secret = create_external_secret(
    cnpg.backup.s3.secret.name,
    observed_xr.metadata.name,
    cnpg.backup.s3.secret.storeRef
    [
      cnpg.backup.s3.secret.accessKey
      cnpg.backup.s3.secret.secretKey
    ]
  )

  # CNPG
  _desired_cluster = create_cnpg_cluster(
    observed_xr.metadata.name,
    observed_xr.spec.instances,
    observed_xr.spec.database,
    observed_xr.spec.storage.size,
    observed_xr.spec.backup.restore,
    observed_xr.spec?.resources?.cnpg
  )

  # Object store
  _desired_object_store = create_object_store(
    observed_xr.metadata.name,
    observed_xr.spec.backup.target.bucket,
    cnpg.backup.s3.endpoint,
    {
      secret = cnpg.backup.s3.secret.name
      accessKey = cnpg.backup.s3.secret.accessKey
      secretKey = cnpg.backup.s3.secret.secretKey
    },
    cnpg.backup.retention,
    observed_xr.spec?.resources?.barman
  )

  # Scheduled backup
  _desired_scheduled_backup = create_scheduled_backup() if not observed_xr.spec.backup.restore else {}

  # Set ready
  # TODO:

  # Update Status
  _desired_xr: {str:any} = {
    **params.dxr
  }

  items: [{str:any}] = [ _desired_xr, _desired_secret, _desired_cluster, _desired_object_store, _desired_scheduled_backup ]
}

create_external_secret: (str, str, StoreRef, [str]) -> {str:any} = lambda name: str, xr_name: str, store_ref: StoreRef, secrets: [str] {
  {
    apiVersion = "external-secrets.io/v1"
    kind = "ExternalSecret"
    metadata = metadata(name, xr_name, "externalsecret.${name}" )
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

create_cnpg_cluster = lambda xr_name, instances: int, database: str, storage_size: str, restore_enabled: bool, resources: Resources {
  {
    apiVersion = "postgresql.cnpg.io/v1"
    kind = "Cluster"
    metadata = metadata(xr_name, xr_name, "cluster")
    spec = {
      instances = instances

      bootstrap = {
        recovery = {
          database = database
          source = "source"
        }
      } if restore_enabled else {
        initdb = {
          database = database
        }
      }

      storage = {
        size = storage_size
      }

      plugins = [
        {
          name = "barman-cloud.cloudnative-pg.io"
          isWALArchiver = True
          parameters = {
            barmanObjectName = "cnpg-backup-s3"
          }
        }
      ] if not restore_enabled else []

      externalClusters =  [
        {
          name = "source"
          plugin = {
            name = "barman-cloud.cloudnative-pg.io"
            parameters = {
              barmanObjectName = "cnpg-backup-s3"
              serverName = name
            }
          }
        }
      ] if restore_enabled else []

      resources = resources
    }
  }
}

create_object_store = lambda xr_name: str, bucket: str, endpoint: str, s3_credentials: S3Credentials, retention: str, resources: Resources {
  {
    apiVersion = "barmancloud.cnpg.io/v1"
    kind = "ObjectStore"
    metadata = metadata("cnpg-backup-s3", xr_name, "objectstore")
    spec = {
      configuration = {
        destinationPath = "s3://${bucket}/"
        endpointURL = endpoint
        s3Credentials = {
          accessKeyId = {
            name = s3_credentials.secret
            key = s3_credentials.accessKey
          }
          secretAccessKey = {
            name = s3_credentials.secret
            key = s3_credentials.accessKey
          }
        }

        wal = {
          compression = "gzip"
        }
      }
      retentionPolicy = retention
      instanceSideCarConfiguration = {
        resources = resources
      }
    }
  }
}

create_scheduled_backup = lambda {
  {
    apiVersion = "postgresql.cnpg.io/v1"
    kind = "ScheduledBackup"
    metadata = metadata("backup", "", "scheduledbackup")
    spec = {
      immediate = True
      schedule = ""
      backupOwnerReference = "self"
      cluster = {
        name = ""
      }
      method = "plugin"
      pluginCOnfiguration = {
        name = "name: barman-cloud.cloudnative-pg.io"
        parameters = {
          barmanObjectName = "cnpg-backup-s3"
        }
      }
    }
  }
}

metadata: (str, str, str) -> {str:any} = lambda name: str, xr_name: str, resource_name: str {
  {
    name = name
    annotations = {
      "krm.kcl.dev/composition-resource-name" = "${resource_name}.${name}"
    }
    labels = {"wieman.cloud/backup" = xr_name}
  }
}
