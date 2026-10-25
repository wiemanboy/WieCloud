test_create_resources = lambda {
  resources = compose(create_params())

  assert get_resource(resources, "ExternalSecret")
  assert get_resource(resources, "Cluster")
  assert get_resource(resources, "ObjectStore")
  assert get_resource(resources, "ScheduledBackup")
}

test_restore_disabled = lambda {
  resources = compose(create_params(False))

  cluster = get_resource(resources, "Cluster")

  assert cluster.spec.bootstrap?.initdb?.database
  assert not cluster.spec.bootstrap?.recovery?.database

  assert cluster.spec.plugins != []
  assert cluster.spec.externalClusters == []
}

test_restore_enabled = lambda {
  resources = compose(create_params(True))

  cluster = get_resource(resources, "Cluster")
  backup = get_resource(resources, "ScheduledBackup")

  assert not cluster.spec.bootstrap?.initdb?.database
  assert cluster.spec.bootstrap?.recovery?.database

  assert cluster.spec.plugins == []
  assert cluster.spec.externalClusters != []

  assert not backup
}

test_cnpg_resource_allocation_memory_limits = lambda {
  resources = compose(create_params(cnpg_resources = {
    limits = {
      memory = "64Mi"
    }
  }))

  cluster = get_resource(resources, "Cluster")

  assert cluster.spec.resources.limits.memory == "64Mi"
}

test_cnpg_resource_allocation_memory_requests = lambda {
  resources = compose(create_params(cnpg_resources = {
    requests = {
      memory = "64Mi"
    }
  }))

  cluster = get_resource(resources, "Cluster")

  assert cluster.spec.resources.requests.memory == "64Mi"
}

test_cnpg_resource_allocation_cpu_requests = lambda {
  resources = compose(create_params(cnpg_resources = {
    requests = {
      cpu = "50m"
    }
  }))

  cluster = get_resource(resources, "Cluster")

  assert cluster.spec.resources.requests.cpu == "50m"
}

create_params= lambda enable_restore: bool = False, cnpg_resources: Resources = None {
  {
    ctx = {
      "apiextensions.crossplane.io/environment" = {
        cnpg = {
          backup = {
            s3 = {
              endpoint = "https://s3.example.com"
              secret = {
                name = "s3-credentials"
                accessKey = "accessKey"
                secretKey = "secretKey"
                storeRef = {
                  kind = "ClusterSecretStore"
                  name = "s3-credentials-store"
                }
              }
            }
            schedule = "0 0 0 * *"
            retention = "14d"
          }
        }
      }
    }
    oxr = {
      apiVersion = "wieman.cloud/v1"
      kind = "CNPG"
      metadata = {
        name = "example"
        namespace = "default"
      }
      spec = {
        database = "test"
        instances = 3
        storage = {
          size = "1Gi"
        }

        backup = {
          restore = enable_restore
          target = {
            bucket = "test-bucket"
          }
        }

        resources = {
          cnpg = cnpg_resources
        }
      }
    }
    ocds = {}
    dxr = {}
  }
}

get_resource: ([{str:any}], str) -> {str:any} = lambda resources: [{str:any}], kind: str {
  [resource for resource in resources if resource.kind == kind]?[0]
}
