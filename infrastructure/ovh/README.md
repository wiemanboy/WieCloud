# OVH

## Cert manager webhook

The `cert-manager-webhook-ovh` chart is used to allow cert-manager to create dns01 challenges via this webhook.

To allow these actions the webhook needs a service account with the correct policies linked to it.

1. Go to the OVH Cloud Manager
2. Go to `Identity, Security & Operations > Identities > Service account > Add a service account`
3. Save the generated credentials
4. Go to `policies > Create policy`
5. Fill in the following values
  Service accounts: `<appropriate service account>`
  Product types: `DNS Zone`
  Resource groups: `<appropriate resource group>`
  Actions: `dnsZone:apiovh:record/create`, `dnsZone:apiovh:record/delete`, `dnsZone:apiovh:record/edit`, `dnsZone:apiovh:refresh`, `dnsZone:apiovh:record/get`, `dnsZone:apiovh:status/get`
6. Create the policy.
7. Add the generated credentials to secret manager:
  Region: `eu-west-gra`
  Path: `wiecloud/cert/ovh`
  Values: `oath2_client_id`, `oauth2_client_secret`
