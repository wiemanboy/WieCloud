test_default_hostname = lambda {
    params = {
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
                name = "my-app"
                namespace = "default"
            }
            spec = {
                image = "nginx:1.27"
                route = {
                    targetPort = 8080
                    subdomain = "app"
                    hostnames = []
                }
                resources = {}
            }
        }

        ocds = {}
        dxr = {
            apiVersion = "wieman.cloud/v1"
            kind = "App"
            metadata = {
                name = "my-app"
                namespace = "default"
            }
            status = {}
        }
    }

    resources = compose(params)

    route = [
        r
        for r in resources
        if r.kind == "HTTPRoute"
    ][0]

    assert route.spec.hostnames == ["app.example.com"]
    assert route.spec.parentRefs[0].name == "main-gateway"
    assert route.spec.parentRefs[0].namespace == "gateway-system"
    assert route.spec.parentRefs[0].sectionName == "https"
}
