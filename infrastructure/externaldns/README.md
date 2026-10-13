# ExternalDNS

## OVH

1. Follow the steps on [ExternalDNS - Creating OVHcloud Credentials](https://kubernetes-sigs.github.io/external-dns/latest/docs/tutorials/ovh/#creating-ovhcloud-credentials) to setup credentials
2. Add the generated credentials to secret manager:
  Region: `eu-west-gra`
  Path: `wiecloud/dns/ovh`
  Values: `application_key`, `secret_key`, `consumer_key`
