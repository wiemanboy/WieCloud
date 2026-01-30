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

## Pull Requests

Pull requests should be created as a draft, this will make the pipelines build a dev image. Once the code is ready for review, the draft status can be removed and a production image will be built.

## Pipelines

There are three main pipelines used in the project:

- `build image`: Builds and pushes an image to an image registry
- `build chart`: Packages and pushes a Helm chart to a Helm chart registry
- `version`: Updates the version of all changed charts abd images in `wiecloud/chart/values.yaml` for deployment

## Helper scripts

The projects includes some helper scripts to be run locally:

- `pipeline/build/scripts/helm/create_helm_build_workflow.sh`: creates a build workflow file for a defined chart using `pipeline/build/scripts/helm/helm_build_<chart_name>.yaml`
- `pipeline/build/scripts/image/create_image_build_workflow.sh`: creates a build workflow file for a defined chart using `pipeline/build/scripts/image/image_build_<image_name>.yaml`
- `pipeline/version/scripts/bump_versions.sh`: bumps the versions of all charts and images by one patch version, used when pipelines are edited

## TODO

### Automation

- [ ] Add pipeline check for wiecloud chart template

### Storage

- [ ] Implement Ceph for better storage management, s3 and to torture myself
- [ ] Figure out backup procedures
- [ ] Link unused disks to vm's
- [ ] Give more storage to nodes

### VPN

- [ ] Setup a VPN

### DNS sinkhole

- [ ] Implement a DNS sinkhole for ads (pihole, technitium)

### Gateway

- [ ] Envoy Gateway?
- [ ] OIDC middleware
