test_check_readiness = lambda {
    desired_resources = [
        _desired_resource("app1.deployment")
        _desired_resource("app2.deployment")
    ]

    observed_resources = [
        _observed_resource("app1.deployment", False)
        _observed_resource("app2.deployment", True)
    ]

    result = check_readiness(desired_resources, observed_resources, readiness.deployment)
    assert not result[0].metadata.annotations["krm.kcl.dev/ready"]
    assert result[1].metadata.annotations["krm.kcl.dev/ready"] == "True"
}

test_check_readiness_unsorted = lambda {
    desired_resources = [
        _desired_resource("app2.deployment")
        _desired_resource("app1.deployment")
        _desired_resource("app3.deployment")
    ]

    observed_resources = [
        _observed_resource("app3.deployment", True)
        _observed_resource("app1.deployment", False)
        _observed_resource("app2.deployment", True)
    ]

    result = check_readiness(desired_resources, observed_resources, readiness.deployment)
    assert result[0].metadata.annotations["krm.kcl.dev/ready"] == "True"
    assert not result[1].metadata.annotations["krm.kcl.dev/ready"]
    assert result[0].metadata.annotations["krm.kcl.dev/ready"] == "True"
}

test_check_readiness_unknown_resources = lambda {
    desired_resources = [
        _desired_resource("app1.deployment")
        _desired_resource("app2.deployment")
    ]

    observed_resources = [
        _observed_resource("app1.service", False)
        _observed_resource("app2.deployment", True)
    ]

    result = check_readiness(desired_resources, observed_resources, readiness.deployment)
    assert not result[0].metadata.annotations["krm.kcl.dev/ready"]
    assert result[1].metadata.annotations["krm.kcl.dev/ready"] == "True"
}

test_check_readiness_uncreated_resources = lambda {
    desired_resources = [
        _desired_resource("app1.deployment")
        _desired_resource("app2.deployment")
    ]

    observed_resources = [
        _observed_resource("app2.deployment", True)
    ]

    result = check_readiness(desired_resources, observed_resources, readiness.deployment)
    assert not result[0].metadata.annotations["krm.kcl.dev/ready"]
    assert result[1].metadata.annotations["krm.kcl.dev/ready"] == "True"
}

_desired_resource = lambda name: str {
    {
        metadata.annotations: {
            "crossplane.io/composition-resource-name": name
        }
    }
}

_observed_resource = lambda name: str, ready: bool {
    {
        metadata.annotations: {
            "crossplane.io/composition-resource-name": name
        }
        status.conditions: [
            {
                type: "Available"
                status: str(ready)
            }
        ]
    }
}
