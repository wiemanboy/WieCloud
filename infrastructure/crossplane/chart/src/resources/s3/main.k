import json

schema ParentRef:
  name: str
  sectionName: str
  namespace: str

schema Resources:
  limits?: Resource
  requests?: Resource

schema Resource:
  cpu?: str
  memory?: str

schema S3Credentials:
  secret: str
  accessKey: str
  secretKey: str

schema Master:
  replicas: int
  resources?: Resources

schema Volume:
  replicas: int
  storage: str
  resources?: Resources

schema Filer:
  replicas: int
  storage: str
  resources?: Resources

compose = lambda params: any {
  ctx: any = params.ctx
  seaweedfs: any = ctx["apiextensions.crossplane.io/environment"]["seaweedfs"]
  network: any = ctx["apiextensions.crossplane.io/environment"]["network"]

  observed_xr: any = params.oxr

  # Password generator
  _desired_password_generator = create_password_generator(
    "${observed_xr.spec.secret.name}-generator",
    observed_xr.metadata.name
  )

  # S3 credentials external secrets
  _desired_s3_credentials = create_s3_credentials_external_Secret(
    observed_xr.spec.secret.name,
    observed_xr.metadata.name,
    "${observed_xr.spec.secret.name}-generator",
  )

  # S3 credentials secret store
  _desired_secret_store_resources = create_secret_store(
    observed_xr.spec.secret.store.name,
    observed_xr.spec.secret.store.kind,
    observed_xr.metadata.name,
    observed_xr.metadata.namespace,
    observed_xr.spec.secret.name,
  )

  # S3 credentials config
  _desired_s3_credentials_config = create_s3_config_external_secret(
    "${observed_xr.spec.secret.name}-config",
    observed_xr.metadata.name,
    observed_xr.spec.secret.store.name,
    observed_xr.spec.secret.name,
  )

  # Seaweedfs
  _desired_seaweed = create_seaweedfs(
    observed_xr.metadata.name,
    seaweedfs.image,
    observed_xr.spec.master,
    observed_xr.spec.volume,
    observed_xr.spec.filer,
    "${observed_xr.spec.secret.name}-config"
  )

  # HTTPRoute
  _desired_httproute = create_httproute(
    observed_xr.metadata.name
    observed_xr.spec.endpoint
    network.gateway
    observed_xr.metadata.namespace
  )

  # Replicator
  _desired_replicator_resources = create_replicator(
    "${observed_xr.metadata.name}-replicator",
    observed_xr.metadata.name,
    seaweedfs.image,
    observed_xr.spec.replicator.storage,
    observed_xr.spec.replicator.resources
  )

  # Set ready

  # Update Status
  _desired_xr: {str:any} = {
    **params.dxr
  }

  items: [{str:any}] = [ _desired_xr, _desired_password_generator, _desired_s3_credentials, *_desired_secret_store_resources, _desired_s3_credentials_config, _desired_seaweed, _desired_httproute, *_desired_replicator_resources ]
}

create_password_generator = lambda name: str, xr_name: str {
  {
    apiVersion = "generators.external-secrets.io/v1alpha1"
    kind = "Password"
    metadata = metadata(name, xr_name, "password")
    spec = {
      length = 42
      symbolCharacters = ""
      symbols = 0
    }
  }
}

create_s3_credentials_external_Secret = lambda name: str, xr_name: str, generator_name: str  {
  {
    apiVersion = "external-secrets.io/v1"
    kind = "ExternalSecret"
    metadata = metadata(name, xr_name, "externalsecret" )
    spec = {
      refreshInterval = "0s"

      target = {
        name = name
      }

      dataFrom = [{
        sourceRef = {
          generatorRef = {
            apiVersion = "generators.external-secrets.io/v1alpha1"
            kind = "Password"
            name = generator_name
          }
        }
        rewrite = [{
          regexp = {
            source = "(.*)"
            target = key
          }
        }]
      } for key in ["accessKey", "secretKey"] ]
    }
  }
}

create_secret_store = lambda name: str, kind: str, xr_name: str, namespace: str, secret_name: str {
  [
    {
      apiVersion = "external-secrets.io/v1"
      kind = "SecretStore"
      metadata = metadata(name, xr_name, "secretstore")
      spec = {
        provider = {
          kubernetes = {
            remoteNamespace = namespace
            server = {
              url = "https://kubernetes.default.svc"
              caProvider = {
                type = "ConfigMap"
                name = "kube-root-ca.crt"
                key = "ca.crt"
              }
            }
            auth = {
              serviceAccount = {
                name = name
                namespace = namespace
              }
            }
          }
        }
      }
    },
    {
      apiVersion = "v1"
      kind = "ServiceAccount"
      metadata = metadata(name, xr_name, "serviceaccount")
    },
    {
      apiVersion = "rbac.authorization.k8s.io/v1"
      kind = "Role"
      metadata = metadata(name, xr_name, "role")
      rules = [{
        apiGroups = [""]
        resources = ["secrets"]
        resourceNames = [secret_name]
        verbs = ["get", "list", "watch"]
      }]
    },
    {
      apiVersion = "rbac.authorization.k8s.io/v1"
      kind = "RoleBinding"
      metadata = metadata(name, xr_name, "rolebinding")
      subjects = [{
        kind = "ServiceAccount"
        name = name
        namespace = namespace
      }]
      roleRef = {
        apiGroup = "rbac.authorization.k8s.io"
        kind = "Role"
        name = name
      }
    },
  ]
}

create_s3_config_external_secret = lambda name: str, xr_name: str, store_name, secret_name: str {
  {
    apiVersion = "external-secrets.io/v1"
    kind = "ExternalSecret"
    metadata = metadata(name, xr_name, "externalsecret" )
    spec = {
      secretStoreRef = {
        kind = "SecretStore"
        name = store_name
      }

      target = {
        name = name
        template = {
          engineVersion = "v2"
          data = {
            "seaweedfs_s3_config.json" = json.encode({
              identities = [{
                name = "admin"
                actions = "Admin"
                credentials = [{
                  accessKey = "{{ .accessKey }}"
                  secretKey = "{{ .secretKey }}"
                }]
              }]
            })
          }
        }
      }

      data = [
        {
          secretKey = target
          remoteRef = {
            key = secret_name
            property = target
          }
        } for target in ["accessKey", "secretKey"]
      ]
    }
  }
}

create_seaweedfs = lambda xr_name: str, image: str, master: Master, volume: Volume, filer: Filer, secret_name: str {
  {
    apiVersion = "seaweed.seaweedfs.com/v1"
    kind = "Seaweed"
    metadata = metadata(xr_name, xr_name, "seaweed")
    spec = {
      image = image
      master = {
        replicas = master.replicas
        volumeSizeLimitMB = 1024
        **master.resources
      }

      volume = {
        replicas = volume.replicas
        kind = "StatefulSet"
        limits = volume?.resources?.limits
        requests = {
          storage = volume.storage
          cpu = volume?.resources?.requests?.cpu
          memory = volume?.resources?.requests?.memory
        }
      }

      filer = {
        replicas = volume.replicas
        persistence = {
          enabled = True
          resources = {
            requests = {
              storage = filer.storage
            }
          }
        }

        s3 = {
          enabled = True
          configSecret = {
            name = secret_name
            key = "seaweedfs_s3_config.json"
          }
        }

        config = """
        [leveldb2]
        enabled = true
        dir = "/data/filerldb2"
        """

        **filer.resources
      }
    }
  }
}

create_httproute = lambda xr_name: str, hostname: str, parent_ref: ParentRef, namespace: str {
  {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind = "HTTPRoute"
    metadata = metadata(xr_name, xr_name,"httproute")
    spec = {
      parentRefs = [parent_ref]
      hostnames = [hostname]
      rules = [{
        matches = [{
          path = {
            type = "PathPrefix"
            value = "/"
          }
        }]
        backendRefs = [{
          name = "${xr_name}-filer"
          namespace = namespace
          port = 8333
        }]
      }]
    }
  }
}

create_replicator = lambda name: str, xr_name: str, image: str, storage: str, resources: Resources {
  [
    {
      apiVersion = "apps/v1"
      kind = "Deployment"
      metadata = metadata(name, xr_name, "deployment")
      spec = {
        replicas = 1
        template = {
          spec = {
            containers = [{
              name = "seaweedfs-replicator"
              image = image
              command = ["weed", "filer.backup", "-filer=${xr_name}-filer:8888"]
              volumeMounts = [
                {
                  name = "backup"
                  mountPath = "/backup"
                },
                {
                  name = "config"
                  mountPath = "/etc/seaweedfs"
                }
              ]
              resources = resources
            }]
            volumes = [
              {
                name = "backup"
                persistentVolumeClaim = {
                  claimName = name
                }
              }
              {
                name = "config"
                configMap = {
                  name = "${name}-config"
                }
              }
            ]
          }
        }
      }
    },
    {
      apiVersion = "v1"
      kind = "PersistentVolumeClaim"
      metadata = metadata(name, xr_name, "persistentvolumeclaim", {
        "k8up.io/backup" = "true"
      })
      spec = {
        accessModes = ["ReadWriteOnce"]
        resources = {
          requests = {
            storage = storage
          }
        }
      }
    },
    {
      apiVersion = "v1"
      kind = "ConfigMap"
      metadata = metadata("${name}-config", xr_name, "configmap")
      data = {
        "replication.toml" = """
        enabled = true
        directory = "/backup"
        is_incremental = false
        """
      }
    }
  ]
}

get_observed_resources_by_resource_type: (any, str) -> [any] = lambda params: any, resource_type: str {
  ocds = params.ocds

  [params.ocds[name]?.Resource for name in params.ocds if name.startswith(resource_type)]
}

set_ready: (any) = lambda resource: any {
  resource.metadata.annotations["krm.kcl.dev/ready"] = "True"
}

metadata = lambda name: str, xr_name: str, resource_name: str, _annotations = {} {
  {
    name = name
    annotations = {
      "krm.kcl.dev/composition-resource-name" = "${resource_name}.${name}",
      **_annotations
    }
    labels = {"wieman.cloud/backup" = xr_name}
  }
}
