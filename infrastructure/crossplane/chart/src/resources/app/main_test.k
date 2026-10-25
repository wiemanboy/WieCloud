test_default_hostname = lambda {
  resources = compose(create_params("my-app", None,  None, [], None))

  route = get_resource(resources, "HTTPRoute")

  assert route.spec.hostnames == ["my-app.example.com"]
}

test_domain_hostname = lambda {
   resources = compose(create_params("my-app", None, "sub-domain", [], None))

  route = get_resource(resources, "HTTPRoute")

  assert route.spec.hostnames == ["sub-domain.example.com"]
  assert route.spec.hostnames != ["my-app.example.com"]
}

test_hostnames = lambda {
  resources = compose(create_params("my-app", None, "sub-domain", [
    "first-domain.example.com"
    "second-domain.example.com"
  ], None))

  route = get_resource(resources, "HTTPRoute")

  assert route.spec.hostnames == [
    "sub-domain.example.com"
    "first-domain.example.com"
    "second-domain.example.com"
    ]
}

test_image = lambda {
  resources = compose(create_params("my-app", "docker.io/repo/custom-image", None, [], None))

  deploy = get_resource(resources, "Deployment")

  assert deploy.spec.template.spec.containers[0].image == "docker.io/repo/custom-image"
}

test_target_port = lambda {
  resources = compose(create_params("my-app", None None, [], 8443))

  svc = get_resource(resources, "Service")
  deploy = get_resource(resources, "Deployment")

  assert svc.spec.ports[0].targetPort == 8443
  assert deploy.spec.template.spec.containers[0].ports[0].containerPort == 8443
}

create_params: (str, str, str, [str], int) -> {str:any} = lambda name: str, image: str, subdomain: str, hostnames: [str], target_port: int {
  {
    ctx = {
      "apiextensions.crossplane.io/environment" = {
        network = {
          hostname = "example.com"
          gateway = {
            name = "main-gateway"
            namespace = "gateway-system"
            sectionName = "https"
          }
        }
      }
    }
    oxr = {
      apiVersion = "wieman.cloud/v1"
      kind = "App"
      metadata = {
        name = name
        namespace = "default"
      }
      spec = {
        image = image
        route = {
          targetPort = target_port
          subdomain = subdomain
          hostnames = hostnames
        }
        resources = {}
      }
    }
    ocds = {}
    dxr = {}
  }
}

get_resource: ([{str:any}], str) -> {str:any} = lambda resources: [{str:any}], kind: str {
  [resource for resource in resources if resource.kind == kind][0]
}
