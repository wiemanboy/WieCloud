{{/*
Generate ArgoCD Application manifest
*/}}
{{- define "base.application" -}}
{{- $name := .name -}}
{{- $config := .config -}}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ $name }}
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://github.com/wiemanboy/WieCloud.git
    targetRevision: master
    path: {{ $config.path }}
  destination:
    server: https://kubernetes.default.svc
    namespace: {{ $config.namespace }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
{{- end }}