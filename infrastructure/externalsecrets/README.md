# External Secrets

## Providers

### OVH

External secrets authentication for OVH is setup via mtls

To generate the mtls certificates for this:

1. Go to the OVH Cloud Manager
2. Go to `Identity, Security & Operations`
3. Go to `Identities > Service Accounts > Add a service account`
4. Go to `Key Management Service > OKMS > Access Certificates > generate an access certificate`
5. Create a certificate that is valid for 1 year
6. Download the private key
7. Download the public key
8. Use `base64 -w 0 <file> | wl-copy` to encode it
9. Fill in the values of the below secret and deploy
10. Done

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
