resource "kubernetes_namespace_v1" "argocd-namespace" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argo" {
  depends_on = [kubernetes_namespace_v1.argocd-namespace]
  name       = "argocd"
  namespace  = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "9.1.6"
  values     = [file("../../infrastructure/argocd/chart/values.yaml")]

  lifecycle {
    ignore_changes = all
  }
}

resource "kubernetes_manifest" "wiecloud-application" {
  depends_on = [helm_release.argo]
  manifest   = yamldecode(file("./argo/wiecloud.application.yaml"))

  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}

resource "kubernetes_manifest" "infrastructure-project" {
  depends_on = [helm_release.argo]
  manifest   = yamldecode(file("./argo/infrastructure.project.yaml"))

  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}
