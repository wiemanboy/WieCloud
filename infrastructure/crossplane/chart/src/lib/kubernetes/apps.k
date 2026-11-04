import schemas.kubernetes

deployment = lambda name: str, xr_name: str, image: str, resources: kubernetes.Resources, port: int = 80, replicas: int = 2 {
    {
        apiVersion: "apps/v1"
        kind: "Deployment"
        metadata: metadata(name, xr_name, "deployment")
        spec: {
            replicas: replicas
            selector.matchLabels: {"wieman.cloud/app" = name}
            template = {
                metadata.labels: {"wieman.cloud/app" = name}
                spec.containers: [{
                    name: "app"
                    image: image
                    ports: [
                        {containerPort = port}
                    ]
                    resources: resources
                }]
            }
        }
    }
}
