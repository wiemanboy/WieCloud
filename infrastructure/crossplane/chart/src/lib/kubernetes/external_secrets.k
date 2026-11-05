import lib.utils
import schemas.kubernetes

external_secret= lambda name: str, xr_name: str, store_ref: kubernetes.StoreRef, secrets: [str] {
  dashed_name = utils.dash_name(name)
  {
    apiVersion = "external-secrets.io/v1"
    kind = "ExternalSecret"
    metadata = metadata(dashed_name, xr_name, "externalsecret" )
    spec = {
      secretStoreRef = {
        kind = store_ref.kind
        name = store_ref.name
      }

      target = {
        name = name
      }

      data = [
        {
          secretKey = secret
          remoteRef = {
            key = name
            property = secret
          }
        } for secret in secrets
      ]
    }
  }
}
