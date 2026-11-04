import schemas.kubernetes

httproute = lambda name: str, xr_name: str, hostnames: [str], parent_ref: kubernetes.ParentRef, backend_ref: kubernetes.BackendRef {
    {
        apiVersion: "gateway.networking.k8s.io/v1"
        kind: "HTTPRoute"
        metadata: metadata(name, xr_name, "httproute")
        spec: {
            parentRefs: [parent_ref]
            hostnames: hostnames
            rules: [{
                matches: [{
                    path: {
                        type: "PathPrefix"
                        value: "/"
                    }
                }]
                backendRefs: [backend_ref]
            }]
        }
    }
}
