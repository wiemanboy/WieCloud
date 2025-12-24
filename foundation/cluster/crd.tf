data "http" "keycloak_crd" {
  url = "https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.4.7/kubernetes/keycloaks.k8s.keycloak.org-v1.yml"
}

data "http" "keycloak_realm_crd" {
  url = "https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.4.7/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml"
}

resource "kubernetes_manifest" "keycloak_crd" {
  manifest = yamldecode(data.http.keycloak_crd.response_body)
}

resource "kubernetes_manifest" "keycloak_realm_crd" {
  manifest = yamldecode(data.http.keycloak_realm_crd.response_body)
}

