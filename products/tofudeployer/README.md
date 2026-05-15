# Tofudeployer

This is a simple go based tool for automatically running tofu commands.

## Usage

### Variables

Variables can be given by providing them as environment variables `TF_VAR_<variable_name>`.

### Kubernetes

This tool is designed to run in a kubernetes cluster as a cronjob. The kubernetes backend can be used for persistence.

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

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: tofudeployer
spec:
  successfulJobsHistoryLimit: 1
  schedule: "0/3 * * * *"
  jobTemplate:
    metadata:
      name: tofudeployer
    spec:
      backoffLimit: 1
      template:
        spec:
          serviceAccountName: tofudeployer
          containers:
          - name: tofudeployer
            {{- with .Values.tofudeployer.image }}
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
            - name: TF_VAR_namespace
              value: {{ .Release.Namespace }}
            - name: TF_VAR_aws_access_key
          restartPolicy: Never
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
