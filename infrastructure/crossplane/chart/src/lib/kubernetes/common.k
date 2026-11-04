metadata: (str, str, str) -> {str:any} = lambda name: str, xr_name: str, resource_name: str {
    {
        name: name
        annotations: {
            "krm.kcl.dev/composition-resource-name": "${name}.${resource_name}"
            "crossplane.io/composition-resource-name": "${name}.${resource_name}"
        }
    }
}
