# External Secrets

## Providers

### OVH

External secrets authentication for OVH is setup via mtls

To generate the mtls certificates for this:

1. Go to the OVH Cloud Manager
2. Go to `Identity, Security & Operations`
3. Go to `Identities > Service Accounts > Add a service account`
4. Go to `Policies > Create policy`
5. Fill in the following values
  Service accounts: `<appropriate service account>`
  Product types: `Secret Manager (OKMS) / Secret`
  Resource groups: `<appropriate resource group>`
  Actions: `CREATE`, `DELETE`, `EDIT`, `READ`
6. Go to `Key Management Service > OKMS > Access Certificates > generate an access certificate`
7. Create a certificate that is valid for 1 year
8. Download the private key
9. Download the public key
10. Use `base64 -w 0 <file> | wl-copy` to encode it
11. Fill in the values of the below secret and deploy
12. Done

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ovh-mtls
  namespace: external-secrets
type: kubernetes.io/tls
data:
  tls.crt: BASE64_CERT_PLACEHOLDER # "client certificate value"
  tls.key: BASE64_KEY_PLACEHOLDER  # "client key value"
  ```
