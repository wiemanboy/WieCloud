observed_xr = option("params").oxr

# Deployment
_desired_deployment: {str:str | {str:{str:any}} | {str:int | {str:{str:any}}}} = {
  apiVersion = "apps/v1"
  kind = "Deployment"
  metadata = {
    name = observed_xr.metadata.name
    annotations = {
      "krm.kcl.dev/composition-resource-name" = "deployment"
    }
    labels = {"wieman.cloud/app" = observed_xr.metadata.name}
  }
  spec = {
    replicas = 2
    selector.matchLabels = {"wieman.cloud/app" = observed_xr.metadata.name}
    template = {
      metadata.labels = {"wieman.cloud/app" = observed_xr.metadata.name}
      spec.containers = [{
        name = "app"
        image = observed_xr.spec.image
        ports = [{containerPort = 80}]
      }]
    }
  }
}

observed_deployment = option("params").ocds["deployment"]?.Resource
if any_true([c.type == "Available" and c.status == "True" for c in observed_deployment?.status?.conditions or []]):
  _desired_deployment.metadata.annotations["krm.kcl.dev/ready"] = "True"

# Service
_desired_service: {str:str | {str:{str:any} | [{str:str | int}]}} = {
  apiVersion = "v1"
  kind = "Service"
  metadata = {
    name = observed_xr.metadata.name
    annotations = {
      "krm.kcl.dev/composition-resource-name" = "service"
    }
    labels = {"wieman.cloud/app" = observed_xr.metadata.name}
  }
  spec = {
    selector = {"wieman.cloud/app" = observed_xr.metadata.name}
    ports = [{protocol = "TCP", port = 8080, targetPort = 80}]
  }
}

observed_service = option("params").ocds["service"]?.Resource
if observed_service?.spec?.clusterIP:
  _desired_service.metadata.annotations["krm.kcl.dev/ready"] = "True"

# Update status
_desired_xr: {str:any} = {
  **option("params").dxr
  status.address = observed_service?.spec?.clusterIP or ""
  status.replicas = observed_deployment?.status?.availableReplicas or 0
}

items = [_desired_deployment, _desired_service, _desired_xr]
