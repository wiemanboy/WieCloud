{{/*
Generate ArgoCD Application manifest
*/}}
{{- define "helm.application" -}}
{{- $name := .name -}}
{{- $config := .config -}}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ $name }}
  namespace: argocd
spec:
  project: default
  source:
    chart: {{ $config.chart }}
    repoURL: {{ $config.repoURL }}
    targetRevision: {{ $config.targetRevision }}
    helm:
      valueFiles: {{ $config.valueFiles}}
      values: {{ $config.values | default "" | nindent 8 }}
  destination:
    server: "https://kubernetes.default.svc"
    namespace: infrastructure
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
---
{{- end }}