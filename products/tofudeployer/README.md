# Tofudeployer

This is a simple go based tool for automatically running tofu commands.

## Variables

Variables can be given by providing them as environment variables `TF_VAR_<variable_name>`.

## Kubernetes

The most effective way to run this is in a cronjob like this:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: tofudeployer
spec:
  successfulJobsHistoryLimit: 1
  concurrencyPolicy: Forbid
  schedule: "0/3 * * * *"
  jobTemplate:
    metadata:
      name: tofudeployer
    spec:
      backoffLimit: 1
      template:
        spec:
          containers:
          - name: tofudeployer
            {{- with .Values.images.tofudeployer.image }}
            image: {{ .registry }}/{{ .repository }}:{{ .version }}
            {{- end }}
            env:
            - name: DRY_RUN
              value: "false"
            - name: REPOSITORY_URL
              value: {{ .Values.targetRepository.url }}
            - name: REPOSITORY_BRANCH
              value: {{ .Values.targetRepository.branch }}
            - name: TOFU_PATH
              value: infrastructure/k8up/tofu
          restartPolicy: Never
```

### State

#### PVC

The local backend can be used for persistence, this also allows to state to be backed up.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: tofudeployer
spec:
  successfulJobsHistoryLimit: 1
  concurrencyPolicy: Forbid
  schedule: "0/3 * * * *"
  jobTemplate:
    metadata:
      name: tofudeployer
    spec:
      backoffLimit: 1
      template:
        spec:
          containers:
          - name: tofudeployer

            resources:
              limits:
                memory: 256Mi
              requests:
                cpu: 2m
                memory: 128Mi

            volumeMounts:
            - name: data
              mountPath: /data
              
          volumes:
          - name: data
            persistentVolumeClaim:
              claimName: tofudeployer-state

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: tofudeployer-state
  annotations:
    k8up.io/backup: "true"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Mi
```

#### Secret

The kubernetes backend can be used for persistence.

```hcl
variable "namespace" {
  description = "Namespace of the kubernetes backend"
  type        = string
}

terraform {
  backend "kubernetes" {
    secret_suffix     = "state"
    in_cluster_config = true
    namespace         = var.namespace
  }
}

```

Make sure to add a service account to allow the tofudeployer to create and lock the secret when running

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: tofudeployer
spec:
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: tofudeployer

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: tofudeployer
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["coordination.k8s.io"]
  resources: ["leases"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tofudeployer
  labels:
    app: tofudeployer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tofudeployer
subjects:
- kind: ServiceAccount
  name: tofudeployer
roleRef:
  kind: Role
  name: tofudeployer
  apiGroup: rbac.authorization.k8s.io
```

### Migrating state

```sh
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: tofustate-migrator
spec:
  restartPolicy: Never
  containers:
    - name: tofustate-migrator
      image: alpine
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: state
          mountPath: /data
  volumes:
    - name: state
      persistentVolumeClaim:
        claimName: tofudeployer-state
EOF
kubectl wait --for=condition=Ready pod/tofustate-migrator --timeout=60s
kubectl cp terraform.tfstate tofustate-migrator:/data/state/terraform.tfstate
kubectl delete pod tofustate-migrator
```
