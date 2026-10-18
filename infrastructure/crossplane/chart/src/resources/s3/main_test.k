test_create_resources = lambda {
  resources = compose(create_test_params())

  assert get_resources(resources, "Password")
  assert len(get_resources(resources, "ExternalSecret")) == 2
  assert get_resources(resources, "ClusterSecretStore")
  # assert get_resources(resources, "Seaweed")
  # assert get_resources(resources, "Deploy")
}

create_test_params = lambda {
  {
    ctx = {
      "apiextensions.crossplane.io/environment" = {
        seaweedfs = {
          image = "registry.io/image:tag"
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
      spec = {}
    }
    ocds = {}
    dxr = {}
  }
}

get_resources: ([{str:any}], str) -> [{str:any}] = lambda resources: [{str:any}], kind: str {
  [resource for resource in resources if resource.kind == kind]
}
