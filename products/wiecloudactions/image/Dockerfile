FROM docker:29.7.2-dind AS docker

FROM alpine:3.24.4

COPY --from=docker /usr/local/bin/docker* /usr/local/bin/
COPY --from=docker /usr/local/bin/containerd* /usr/local/bin/

RUN apk add --no-cache \
    bash \
    jq \
    yq \
    git \
    curl \
    wget \
    helm \
    nodejs

ENTRYPOINT ["/bin/bash"]
