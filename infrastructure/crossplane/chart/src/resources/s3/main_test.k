test_create_resources = lambda {
  resources = compose(create_test_params())

  assert get_resources(resources, "Password")
  assert len(get_resources(resources, "ExternalSecret")) == 2
  assert get_resources(resources, "SecretStore")
  assert get_resources(resources, "Seaweed")
  assert get_resources(resources, "HTTPRoute")
  assert get_resources(resources, "Deployment")
}

test_disable_replicator = lambda {
  params = create_test_params()
  params.oxr.spec.replicator.enabled = False
  resources = compose(params)

  assert len(get_resources(resources, "PersistentVolumeClaim")) == 0
  assert len(get_resources(resources, "Deployment")) == 0
}

create_test_params = lambda  {
  {
    ctx = {
      "apiextensions.crossplane.io/environment" = {
        seaweedfs = {
          image = "registry.io/image:tag"
        }
        network = {
          gateway = {
            name = "test"
            sectionName = "test"
            namespace = "test"
          }
        }
      }
    }
    oxr = {
      apiVersion = "wieman.cloud/v1"
      kind = "S3"
      metadata = {
        name = "test-s3"
        namespace = "default"
      }
      spec = {
        endpoint = "s3.example.com"

        secret = {
          name = "test-s3-credentials"
          store = {
            name = "test-s3-credentials-store"
          }
        }

        master = {
          replicas = 1
        }

        volume = {
          replicas = 1
          storage = "1Gi"
        }

        filer = {
          replicas = 1
          storage = "1Gi"
        }

        replicator = {
          enabled = True
          storage = "1Gi"
        }
      }
    }
    ocds = {}
    dxr = {}
  }
}

get_resources: ([{str:any}], str) -> [{str:any}] = lambda resources: [{str:any}], kind: str {
  [resource for resource in resources if resource.kind == kind]
}
