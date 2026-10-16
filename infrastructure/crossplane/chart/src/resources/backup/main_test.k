test_create_schedule = lambda {
  resources = compose(create_test_params([create_test_backup()], []))

  schedules = get_resources(resources, "Schedule")

  assert len(schedules) == 1
}

test_create_2_schedules = lambda {
  resources = compose(create_test_params([create_test_backup(), create_test_backup()], []))

  schedules = get_resources(resources, "Schedule")

  assert len(schedules) == 2
}

test_create_external_secrets = lambda {
  resources = compose(create_test_params([create_test_backup()], []))

  secrets = get_resources(resources, "ExternalSecret")

  assert len(secrets) == 2
}

test_create_1_restore_with_1_backup = lambda {
  resources = compose(create_test_params([create_test_backup()], [create_test_restore()]))

  restores = get_resources(resources, "Restore")

  assert len(restores) == 1
}

test_create_2_restores_with_1_backup = lambda {
  resources = compose(create_test_params([create_test_backup()], [create_test_restore(), create_test_restore()]))

  restores = get_resources(resources, "Restore")

  assert len(restores) == 2
}

test_create_1_restore_with_2_backups = lambda {
  resources = compose(create_test_params([create_test_backup(), create_test_backup()], [create_test_restore()]))

  restores = get_resources(resources, "Restore")

  assert len(restores) == 1
}

test_create_2_restores_with_2_backups = lambda {
  resources = compose(create_test_params([create_test_backup(), create_test_backup()], [create_test_restore(), create_test_restore()]))

  restores = get_resources(resources, "Restore")

  assert len(restores) == 2
}

test_create_external_secret_naming = lambda {
  secret = create_external_secret("name/to/dash", "xr_name", {kind = "kind", name = ""}, [])

  assert secret.metadata.name == "name-to-dash"
}

test_create_secret_1_secret = lambda {
  secret = create_external_secret("name", "xr_name", {kind = "kind", name = ""}, ["test"])

  assert len(secret.spec.data) == 1
}

test_create_secret_2_secrets = lambda {
  secret = create_external_secret("name", "xr_name", {kind = "kind", name = ""}, ["test0", "test1"])

  assert len(secret.spec.data) == 2
}

test_disable_backups = lambda {
  resources = compose(create_test_params([create_test_backup()], [], enabled=False))

  schedules = get_resources(resources, "Schedule")

  assert len(schedules) == 0
}

test_overwrite_backup_pod_security_context = lambda {
  resources = compose(create_test_params([create_test_backup()], [], backup_pod_security_context={
    runAsUser = 33
    fsGroup = 33
  }))

  schedules = get_resources(resources, "Schedule")

  assert schedules[0].spec.backup.podSecurityContext.runAsUser == 33
  assert schedules[0].spec.backup.podSecurityContext.fsGroup == 33
}

create_test_params = lambda backups: [{str:any}], restores: [{str:any}], enabled: bool = True, name: str = "backup", bucket: str = "backup-bucket", backup_pod_security_context: {str:any} = {} {
  {
    ctx = {
      "apiextensions.crossplane.io/environment" = {
        backups = backups
      }
    }
    oxr = {
      apiVersion = "wieman.cloud/v1"
      kind = "Backup"
      metadata = {
        name = name
        namespace = "default"
      }
      spec = {
        enabled = enabled

        target = {
          bucket = bucket
        }

        restores = restores

        backup = {
          podSpec = {
            securityContext = backup_pod_security_context
          }
        }
      }
    }
    ocds = {}
    dxr = {}
  }
}

create_test_backup = lambda {
  {
    name = "example"
    s3 = {
      endpoint = "https://s3.example.com"
      secret = {
        name = "credentials"
        accessKey = "access_key"
        secretKey = "secret_key"
        storeRef = {
          kind = "ClusterSecretStore"
          name = "credentials-store"
        }
      }
    }
    repo = {
      secret = {
        name = "password"
        password = "password"
        storeRef = {
          kind = "ClusterSecretStore"
          name = "password-store"
        }
      }
    }
    schedule = {
      backup = "0 12 * * *"
      check = "30 12 * * *"
      prune = "0 13 * * *"
    }
    retention = {
      keepLast = 5
      keepDaily = 14
    }
  }
}

create_test_restore = lambda {
  {
    name = "restore"
    enabled = True
    fromBackup = "example"
    snapshot = ""
    claim = {
      name = "pvc"
    }
  }
}

get_resources = lambda resources: [{str:any}], kind: str {
  [resource for resource in resources if resource.kind == kind]
}
