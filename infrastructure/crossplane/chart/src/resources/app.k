ctx: any = option("params").ctx
network: any = ctx["apiextensions.crossplane.io/environment"]["network"]

observed_xr: any = option("params").oxr

metadata: (str) -> {str:any} = lambda resource_name: str {
  {
    name = observed_xr.metadata.name
    annotations = {
      "krm.kcl.dev/composition-resource-name" = resource_name
    }
    labels = {"wieman.cloud/app" = observed_xr.metadata.name}
  }
}

default_hostname: str = "${observed_xr.spec.route.subdomain or observed_xr.metadata.name}.${network.hostname}"
hostnames: [str] = [
    default_hostname,
    *observed_xr.spec.route.hostnames
]

# Deployment
_desired_deployment: {str:any} = {
  apiVersion = "apps/v1"
  kind = "Deployment"
  metadata = metadata("deployment")
  spec = {
    replicas = 2
    selector.matchLabels = {"wieman.cloud/app" = observed_xr.metadata.name}
    template = {
      metadata.labels = {"wieman.cloud/app" = observed_xr.metadata.name}
      spec.containers = [{
        name = "app"
        image = observed_xr.spec.image
        ports = [{containerPort = observed_xr.spec.route.targetPort}]
        resources = observed_xr.spec.resources
      }]
    }
  }
}

observed_deployment: any = option("params").ocds["deployment"]?.Resource
if any_true([c.type == "Available" and c.status == "True" for c in observed_deployment?.status?.conditions or []]):
  _desired_deployment.metadata.annotations["krm.kcl.dev/ready"] = "True"

# Service
_desired_service: {str:any} = {
  apiVersion = "v1"
  kind = "Service"
  metadata = metadata("service")
  spec = {
    selector = {"wieman.cloud/app" = observed_xr.metadata.name}
    ports = [{protocol = "TCP", port = 8080, targetPort = observed_xr.spec.route.targetPort}]
  }
}

observed_service: any = option("params").ocds["service"]?.Resource
if observed_service?.spec?.clusterIP:
  _desired_service.metadata.annotations["krm.kcl.dev/ready"] = "True"

# HTTPRoute
_desired_route: {str:any} = {
  apiVersion = "gateway.networking.k8s.io/v1"
  kind = "HTTPRoute"
  metadata = metadata("httproute")
  spec = {
    parentRefs = [network.gateway]
    hostnames = hostnames
    rules = [{
      matches = [{
        path = {
          type = "PathPrefix"
          value = "/"
        }
      }]
      backendRefs = [{
        name = _desired_service.metadata.name
        namespace = observed_service.metadata.namespace
        port = 8080
      }]
    }]
  }
}

observed_route: any = option("params").ocds["httproute"]?.Resource
if observed_route?.spec?.hostnames?[0]:
  _desired_route.metadata.annotations["krm.kcl.dev/ready"] = "True"

# Update status
_desired_xr: {str:any} = {
  **option("params").dxr
  status.address = observed_service?.spec?.clusterIP or ""
  status.hostname = observed_route?.spec?.hostnames?[0] or ""
  status.replicas = observed_deployment?.status?.availableReplicas or 0
}

items: [{str:any}] = [_desired_deployment, _desired_service, _desired_route, _desired_xr]
