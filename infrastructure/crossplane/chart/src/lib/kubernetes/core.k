service = lambda name: str, xr_name: str, port: int = 80, target_port: int = 80 {
    {
        apiVersion: "v1"
        kind: "Service"
        metadata: metadata(name, xr_name, "service")
        spec = {
            selector = {"wieman.cloud/app" = name}
            ports = [{
                protocol = "TCP"
                port = port
                targetPort = target_port
            }]
        }
    }
}
