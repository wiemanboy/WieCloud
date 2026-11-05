import regex

readiness = {
    deployment: lambda resource -> bool {
        any_true([condition.type == "Available" and condition.status == "True" for condition in resource?.status?.conditions or []])
    }
    service: lambda resource -> bool {
        resource?.spec?.clusterIP != "" or None or Undefined
    }
    httproute: lambda resource -> bool {
        # TODO: Check backend readiness
        any_true([condition.type == "Accepted" and condition.status == "True" for condition in resource?.status?.parents?[0]?.conditions or []])
    }
    external_secret: lambda resource -> bool {
        any_true([condition.type == "Ready" and condition.status == "True" for condition in resource.status?.conditions or []])
    }
    schedule: lambda resource -> bool {
        any_true([condition.type == "Ready" and condition.status == "True" for condition in resource.status?.conditions or []])
    }
    restore: lambda resource -> bool {
        any_true([condition.type == "Ready" and condition.status == "True" for condition in resource.status?.conditions or []])
    }
}

name_key = "crossplane.io/composition-resource-name"

set_ready: (any) = lambda resource: any {
    resource.metadata.annotations["krm.kcl.dev/ready"] = "True"
}

check_readiness = lambda desired_resources: [any], observed_resources: [any], is_available: (any) -> bool {
    [(desired | {
        metadata.annotations: {"krm.kcl.dev/ready": "True"}
    }) if any_true([desired?.metadata?.annotations?[name_key] == observed?.metadata?.annotations?[name_key] and is_available(observed) for observed in observed_resources]) else desired for desired in desired_resources]
}

get_resources_by_resource_kind = lambda resource_type: str, resources: [any] {
    [resource for resource in resources if resource?.kind == resource_type]
}

get_resource_by_name_and_kind = lambda name: str, kind: str, resources: [any] {
    [resource for resource in get_resources_by_resource_kind(kind, resources) if regex.split(resource.metadata.annotations[name_key], "\.")?[0] == name]?[0]
}
