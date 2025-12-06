{{/*
Generate ArgoCD Application manifest
*/}}
{{- define "base.application" -}}
{{- $name := .name -}}
{{- $config := .config -}}
{{- if $config.deploy -}}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ $name }}
  namespace: argocd
spec:
  project: infrastructure
  source:
    chart: {{ $name }}
    repoURL: harbor.wieman.cloud/infrastructure
    targetRevision: {{ $config.target }}
    helm:
      values: |
{{ toYaml $config.values | indent 8 }}
  destination:
    server: https://kubernetes.default.svc
    namespace: {{ $config.namespace }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
{{- end -}}
{{- end }}