# DragonflyDB

## Usage

To create a dragonfly instance use the following config:

```yaml
apiVersion: dragonflydb.io/v1alpha1
kind: Dragonfly
metadata:
  name: dragonfly-name
spec:
  replicas: 3

  args:
    - --proactor_threads=1

  authentication:
    passwordFromSecret:
      name: dragonfly-credentials
      key: password

  resources:
    limits:
      memory: 320Mi
    requests:
      cpu: 50m
      memory: 256Mi
```

Dragonfly counts the amount of threads based on the amount of cpu available, therefore we set threads to one using `--proactor_threads=1`. Every thread uses 256Mi of memory, dragonfly keeps a percentage for other tasks, therefore we set the limit to 320Mi. Setting memory any lower will crash the pod.

Generating credentials using external-secrets:

```yaml
apiVersion: generators.external-secrets.io/v1alpha1
kind: Password
metadata:
  name: dragonfly-credentials
spec:
  length: 42
  symbolCharacters: ""
  symbols: 0
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: dragonfly-credentials
spec:
  refreshInterval: 0s
  target:
    name: dragonfly-credentials
  dataFrom:
  - sourceRef:
       generatorRef:
         apiVersion: generators.external-secrets.io/v1alpha1
         kind: Password
         name: dragonfly-credentials
```
