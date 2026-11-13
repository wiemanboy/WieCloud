FROM alpine/helm:4.2.3 AS helm
FROM docker:29.7.2-dind AS docker

FROM alpine:3.18.2

COPY --from=docker /usr/local/bin/docker* /usr/local/bin/
COPY --from=docker /usr/local/bin/containerd* /usr/local/bin/

COPY --from=helm /usr/bin/helm /usr/bin/helm

RUN apk update && apk add --no-cache \
    ca-certificates \
    bash \
    jq \
    yq \
    git \
    curl \
    wget \
    make \
    zip \
    unzip \
    openssh-client \
    gpg


ENTRYPOINT ["/bin/bash"]
