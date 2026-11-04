readiness = {
    deployment: lambda resource -> bool {
        any_true([condition.type == "Available" and condition.status == "True" for condition in resource?.status?.conditions or []])
    }
    service: lambda resource -> bool {
        resource?.spec?.clusterIP
    }
    httproute: lambda resource -> bool {
        # TODO: Check backend readiness
        any_true([condition.type == "Accepted" and condition.status == "True" for condition in resource?.status?.parents?[0]?.conditions or []])
    }
}

name_key = "krm.kcl.dev/composition-resource-name"

set_ready: (any) = lambda resource: any {
    resource.metadata.annotations["krm.kcl.dev/ready"] = "True"
}

get_resources_by_resource_kind = lambda resources: [any], resource_type: str {
    [resource for resource in resources if resource.kind == resource_type]
}

check_readiness = lambda desired_resources: [any], observed_resources: [any], is_available: (any) -> bool {
    [(desired | {
        metadata.annotations: {"krm.kcl.dev/ready": "True"}
    }) if any_true([desired.metadata.annotations[name_key] == observed.metadata.annotations[name_key] and is_available(observed) for observed in observed_resources]) else desired for desired in desired_resources]
}
