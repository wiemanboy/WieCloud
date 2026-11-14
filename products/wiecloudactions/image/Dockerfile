FROM alpine:3.24.4

RUN apk add --no-cache \
    bash \
    jq \
    yq \
    git \
    curl \
    wget \
    podman \
    podman-docker \
    helm \
    nodejs

RUN ln -s /usr/bin/podman /usr/local/bin/docker
ENTRYPOINT ["/bin/bash"]
