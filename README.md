# WieCloud

## Structure

### Global

- `foundation/`: Deployment of underlying nodes and cluster configuration
- `infrastructure/`: Helm charts for infrastructure, used to keep applications running
- `applications/`: Helm charts for applications, used by end users
- `pipelines/`: Helper scripts and CI/CD pipelines
- `wiecloud/`: Deployment chart looked at by ArgoCD to deploy the whole stack
- `env.yaml`: Environment configuration for tofu (will probably be moved in the future)

### Chart

Charts are structured as default Helm charts:

```txt
chart
    ├── Chart.yaml
    ├── templates
    └── values.yaml
```

the path must be `<project>/<chart_name>/chart/`

### Image

Images are usually placed next to the chart it is used for, structured as follows:

```txt
├── chart
└── <image_name>
    └── image
        ├── Dockerfile
        └── Image.yaml
```

`Image.yaml` is used to define metadata about the image structured the same as a Chart.yaml, and must contain at least the following:

```yaml
name: <image_name>
version: 0.0.0
```

## TODO

### Automation

- [ ] Add pipeline check for wiecloud chart template

### Storage

- [ ] Implement [Garage](https://git.deuxfleurs.fr/Deuxfleurs/garage/src/branch/main-v2/script/helm) for s3 storage
- [ ] Figure out backup procedures
- [ ] Link unused disks to vm's
- [ ] Give more storage to nodes
- [ ] Set longhorn storage engine V2

### VPN

- [ ] Setup a VPN

### DNS sinkhole

- [ ] Implement a DNS sinkhole for ads (pihole, technitium)

### Gateway

- [ ] Envoy Gateway?
- [ ] OIDC middleware
