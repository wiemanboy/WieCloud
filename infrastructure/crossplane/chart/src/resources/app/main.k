import lib.kubernetes
import lib.crossplane

compose = lambda params: any {
    ctx: any = params.ctx
    network: any = ctx["apiextensions.crossplane.io/environment"]["network"]

    observed_xr: any = params.oxr

    default_hostname: str = "${observed_xr.spec.route.subdomain or observed_xr.metadata.name}.${network.hostname}"
    hostnames: [str] = [
        default_hostname
        *observed_xr.spec.route.hostnames
    ]

    # Create resources
    _desired_deployment = kubernetes.deployment(observed_xr.metadata.name, observed_xr.metadata.name, observed_xr.spec.image, observed_xr.spec.resources, observed_xr.spec.route.targetPort, 2)
    _desired_service = kubernetes.service(observed_xr.metadata.name, observed_xr.metadata.name, 8080, observed_xr.spec.route.targetPort)
    _desired_route = kubernetes.httproute(observed_xr.metadata.name, observed_xr.metadata.name, hostnames, {
        name = network.gateway.name
        sectionName = network.gateway.sectionName
        namespace = network.gateway.namespace
    }, {
        name = _desired_service.metadata.name
        namespace = observed_xr.metadata.namespace
        port = 8080
    })

    # Check readiness
    observed_resources = [value.Resource for _, value in params.ocds]
    _desired_deployments = crossplane.check_readiness([_desired_deployment], observed_resources, crossplane.readiness.deployment)
    _desired_services = crossplane.check_readiness([_desired_service], observed_resources, crossplane.readiness.service)
    _desired_httproutes = crossplane.check_readiness([_desired_route], observed_resources, crossplane.readiness.httproute)

    # Update status
    _desired_xr: {str:any} = {
        **params.dxr
        status.hostname: crossplane.get_resource_by_name_and_kind(observed_xr.metadata.name, "HTTPRoute", observed_resources)?.spec?.hostnames?[0] or ""
        status.replicas: crossplane.get_resource_by_name_and_kind(observed_xr.metadata.name, "Deployment", observed_resources)?.status?.availableReplicas or 0
    }

    items: [{str:any}] = [*_desired_deployments, *_desired_services, *_desired_httproutes, _desired_xr]
}
